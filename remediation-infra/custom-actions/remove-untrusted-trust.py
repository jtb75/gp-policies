"""
Remove untrusted principals from IAM role trust policies.

Pairs with CCR: JTB75 - IAM roles with untrusted account trust relationships

Compares each AWS principal in the role's AssumeRolePolicyDocument against
the trusted account lists. Removes statements with wildcard ("*") principals
and strips untrusted account ARNs from multi-principal statements.
Service principals (e.g. ec2.amazonaws.com) are always preserved.

IAM Permissions required:
- iam:GetRole
- iam:UpdateAssumeRolePolicy
"""

import json

import boto3
from botocore.exceptions import ClientError

from wiz.context import AwsRemediationContext
from wiz.models import TargetRemediationArgs
from wiz.logger import logger
from wiz.safe_remediate import remediate_and_log_error

TRUSTED_ACCOUNTS = {
    "123456789012",
    "234567890123",
    "345678901234",
}


def _extract_account_id(arn):
    """Extract the account ID from an IAM ARN."""
    parts = arn.split(":")
    if len(parts) >= 5:
        return parts[4]
    return None


def _is_trusted_principal(principal):
    """Check if an AWS principal is trusted (in the trusted accounts list)."""
    if principal == "*":
        return False
    account_id = _extract_account_id(principal)
    if account_id and account_id in TRUSTED_ACCOUNTS:
        return True
    return False


def _clean_trust_policy(policy):
    """Remove untrusted AWS principals from trust policy statements.

    Returns the cleaned policy and a list of removed principals.
    """
    cleaned_statements = []
    removed_principals = []

    for statement in policy.get("Statement", []):
        if statement.get("Effect") != "Allow":
            cleaned_statements.append(statement)
            continue

        principal = statement.get("Principal", {})

        # Handle Principal: "*" (any entity)
        if principal == "*":
            removed_principals.append("*")
            continue

        aws_principals = principal.get("AWS")
        if aws_principals is None:
            # No AWS principals (e.g. Service-only statement) — keep it
            cleaned_statements.append(statement)
            continue

        # Normalize to list
        if isinstance(aws_principals, str):
            aws_principals = [aws_principals]

        # Filter to only trusted principals
        trusted = [p for p in aws_principals if _is_trusted_principal(p)]
        untrusted = [p for p in aws_principals if not _is_trusted_principal(p)]
        removed_principals.extend(untrusted)

        if not trusted:
            # All AWS principals in this statement were untrusted — drop it
            # But preserve if there are also Service principals
            other_principals = {
                k: v for k, v in principal.items() if k != "AWS"
            }
            if other_principals:
                statement = dict(statement)
                statement["Principal"] = other_principals
                cleaned_statements.append(statement)
            continue

        # Rebuild the statement with only trusted principals
        statement = dict(statement)
        statement["Principal"] = dict(principal)
        statement["Principal"]["AWS"] = trusted[0] if len(trusted) == 1 else trusted
        cleaned_statements.append(statement)

    policy["Statement"] = cleaned_statements
    return policy, removed_principals


def remediate(context: AwsRemediationContext):
    remediation_args: TargetRemediationArgs = context.get_remediation_args()

    role_name = remediation_args.name
    region = remediation_args.region

    logger.info("Starting untrusted trust removal", role=role_name, region=region)

    session: boto3.Session = context.get_session()
    iam = session.client("iam", region_name=region)

    # Get the current trust policy
    try:
        response = iam.get_role(RoleName=role_name)
        trust_policy = response["Role"]["AssumeRolePolicyDocument"]
    except ClientError as e:
        error_msg = e.response["Error"]["Message"]
        logger.error("Failed to get role", role=role_name, error=error_msg)
        raise Exception(error_msg)

    # Clean the trust policy
    cleaned_policy, removed = _clean_trust_policy(trust_policy)

    if not removed:
        raise Exception(
            f"Role {role_name} has no untrusted principals to remove. "
            "A scan may not have run yet to close the finding."
        )

    logger.info(
        "Removing untrusted principals",
        role=role_name,
        removed=removed,
    )

    if not cleaned_policy.get("Statement"):
        raise Exception(
            f"Role {role_name} would have an empty trust policy after cleanup. "
            "Manual review required."
        )

    # Update the trust policy
    try:
        iam.update_assume_role_policy(
            RoleName=role_name,
            PolicyDocument=json.dumps(cleaned_policy),
        )
    except ClientError as e:
        error_msg = e.response["Error"]["Message"]
        logger.error("Failed to update trust policy", role=role_name, error=error_msg)
        raise Exception(error_msg)

    logger.info(
        "Successfully cleaned trust policy",
        role=role_name,
        removed_principals=removed,
    )


if __name__ == "__main__":
    remediate_and_log_error(remediate)
