"""
Deactivate IAM access keys that have exceeded their rotation threshold.

Pairs with CCRs:
- JTB75 - Service account access keys should be rotated every 90 days
- JTB75 - User access keys should be rotated every 30 days
- JTB75 - Vendor access keys should be rotated every 60 days
- JTB75 - Untagged access keys should be rotated every 30 days

Checks each active access key's age and deactivates keys that exceed the
threshold for the user's type tag (service=90d, vendor=60d, user/default=30d).

Deactivated key IDs are saved as a tag (wiz:deactivated-keys) on the IAM
user, enabling the revert function to re-activate them.

IAM Permissions required (remediate):
- iam:ListAccessKeys
- iam:GetAccessKeyLastUsed
- iam:UpdateAccessKey
- iam:ListUserTags
- iam:TagUser

IAM Permissions required (revert):
- iam:UpdateAccessKey
- iam:ListUserTags
- iam:UntagUser
"""

from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

from wiz.context import AwsRemediationContext
from wiz.models import TargetRemediationArgs
from wiz.logger import logger
from wiz.safe_remediate import remediate_and_log_error

# Rotation thresholds in days by user type tag
THRESHOLDS = {
    "service": 90,
    "vendor": 60,
    "user": 30,
}
DEFAULT_THRESHOLD = 30

BACKUP_TAG_KEY = "wiz:deactivated-keys"


def _get_user_type(iam, user_name):
    """Get the type tag value for an IAM user."""
    try:
        response = iam.list_user_tags(UserName=user_name)
        for tag in response.get("Tags", []):
            if tag["Key"] == "type":
                return tag["Value"]
    except ClientError:
        pass
    return None


def remediate(context: AwsRemediationContext):
    remediation_args: TargetRemediationArgs = context.get_remediation_args()

    user_name = remediation_args.name
    region = remediation_args.region

    logger.info("Starting stale access key deactivation", user=user_name, region=region)

    session: boto3.Session = context.get_session()
    iam = session.client("iam", region_name=region)

    # Determine threshold based on user type
    user_type = _get_user_type(iam, user_name)
    threshold_days = THRESHOLDS.get(user_type, DEFAULT_THRESHOLD)
    logger.info("Using threshold", user=user_name, type=user_type, threshold_days=threshold_days)

    # List access keys
    try:
        response = iam.list_access_keys(UserName=user_name)
    except ClientError as e:
        error_msg = e.response["Error"]["Message"]
        logger.error("Failed to list access keys", user=user_name, error=error_msg)
        raise Exception(error_msg)

    now = datetime.now(timezone.utc)
    deactivated = []

    for key_meta in response["AccessKeyMetadata"]:
        key_id = key_meta["AccessKeyId"]
        status = key_meta["Status"]
        create_date = key_meta["CreateDate"]

        if status != "Active":
            continue

        age_days = (now - create_date).days
        if age_days <= threshold_days:
            continue

        logger.info(
            "Deactivating stale key",
            user=user_name,
            key_id=key_id,
            age_days=age_days,
            threshold_days=threshold_days,
        )

        try:
            iam.update_access_key(
                UserName=user_name,
                AccessKeyId=key_id,
                Status="Inactive",
            )
            deactivated.append(key_id)
        except ClientError as e:
            error_msg = e.response["Error"]["Message"]
            logger.error("Failed to deactivate key", user=user_name, key_id=key_id, error=error_msg)
            raise Exception(error_msg)

    if not deactivated:
        raise Exception(
            f"User {user_name} has no active keys exceeding {threshold_days} days. "
            "A scan may not have run yet to close the finding."
        )

    # Save deactivated key IDs as a tag for revert
    deactivated_value = ",".join(deactivated)
    try:
        iam.tag_user(
            UserName=user_name,
            Tags=[{"Key": BACKUP_TAG_KEY, "Value": deactivated_value}],
        )
        logger.info("Saved deactivated keys to tag", user=user_name, keys=deactivated_value)
    except ClientError as e:
        logger.warning(
            "Failed to save backup tag",
            user=user_name,
            error=e.response["Error"]["Message"],
        )

    logger.info(
        "Successfully deactivated stale access keys",
        user=user_name,
        deactivated=deactivated,
    )


def revert(context: AwsRemediationContext):
    remediation_args: TargetRemediationArgs = context.get_remediation_args()

    user_name = remediation_args.name
    region = remediation_args.region

    logger.info("Starting access key reactivation", user=user_name, region=region)

    session: boto3.Session = context.get_session()
    iam = session.client("iam", region_name=region)

    # Get the backup tag
    try:
        response = iam.list_user_tags(UserName=user_name)
        tags = {t["Key"]: t["Value"] for t in response.get("Tags", [])}
    except ClientError as e:
        error_msg = e.response["Error"]["Message"]
        logger.error("Failed to get user tags", user=user_name, error=error_msg)
        raise Exception(error_msg)

    deactivated_value = tags.get(BACKUP_TAG_KEY)
    if not deactivated_value:
        raise Exception(
            f"User {user_name} has no deactivated keys tag ({BACKUP_TAG_KEY}). "
            "Cannot revert."
        )

    key_ids = deactivated_value.split(",")
    logger.info("Re-activating keys", user=user_name, keys=key_ids)

    for key_id in key_ids:
        try:
            iam.update_access_key(
                UserName=user_name,
                AccessKeyId=key_id,
                Status="Active",
            )
            logger.info("Re-activated key", user=user_name, key_id=key_id)
        except ClientError as e:
            error_msg = e.response["Error"]["Message"]
            logger.error("Failed to re-activate key", user=user_name, key_id=key_id, error=error_msg)
            raise Exception(error_msg)

    # Remove the backup tag
    try:
        iam.untag_user(UserName=user_name, TagKeys=[BACKUP_TAG_KEY])
    except ClientError as e:
        logger.warning(
            "Failed to remove backup tag",
            user=user_name,
            error=e.response["Error"]["Message"],
        )

    logger.info("Successfully reverted access key deactivation", user=user_name)


if __name__ == "__main__":
    remediate_and_log_error(remediate)
