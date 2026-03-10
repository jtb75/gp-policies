"""
Auto-tag IAM roles containing "consumer" in the name with type:consumer.

Pairs with CCR: JTB75 - Consumer roles missing type:consumer tag

IAM Permissions required:
- iam:TagRole
- iam:GetRole
"""

import boto3
from botocore.exceptions import ClientError

from wiz.context import AwsRemediationContext
from wiz.models import TargetRemediationArgs
from wiz.logger import logger
from wiz.safe_remediate import remediate_and_log_error


TAG_KEY = "type"
TAG_VALUE = "consumer"


def remediate(context: AwsRemediationContext):
    remediation_args: TargetRemediationArgs = context.get_remediation_args()

    role_name = remediation_args.name
    region = remediation_args.region

    logger.info("Starting consumer role tagging", role=role_name, region=region)

    session: boto3.Session = context.get_session()
    iam = session.client("iam", region_name=region)

    # Verify the role exists and check current tags
    try:
        response = iam.get_role(RoleName=role_name)
        existing_tags = {t["Key"]: t["Value"] for t in response["Role"].get("Tags", [])}
    except ClientError as e:
        error_msg = e.response["Error"]["Message"]
        logger.error("Failed to get role", role=role_name, error=error_msg)
        raise Exception(error_msg)

    if existing_tags.get(TAG_KEY) == TAG_VALUE:
        raise Exception(
            f"Role {role_name} already has tag {TAG_KEY}:{TAG_VALUE}. "
            "A scan may not have run yet to close the finding."
        )

    # Apply the tag
    try:
        iam.tag_role(
            RoleName=role_name,
            Tags=[{"Key": TAG_KEY, "Value": TAG_VALUE}],
        )
    except ClientError as e:
        error_msg = e.response["Error"]["Message"]
        logger.error("Failed to tag role", role=role_name, error=error_msg)
        raise Exception(error_msg)

    logger.info("Successfully tagged role", role=role_name, tag=f"{TAG_KEY}:{TAG_VALUE}")


if __name__ == "__main__":
    remediate_and_log_error(remediate)
