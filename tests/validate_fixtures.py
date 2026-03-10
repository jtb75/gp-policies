"""
Validate all test fixtures against their corresponding rules.

Runs each fixture through the Wiz cloudConfigurationRuleJsonTest API
and checks the result matches the expected outcome (pass/fail/skip).

Usage:
    source .env
    python tests/validate_fixtures.py
"""

import base64
import json
import os
import sys

import requests

HEADERS_AUTH = {"Content-Type": "application/x-www-form-urlencoded"}
HEADERS = {"Content-Type": "application/json"}

QUERY_JSON = """
    query RunCloudRegoRuleTestWithJson($rule: String!, $json: JSON!) {
      cloudConfigurationRuleJsonTest(rule: $rule, json: $json) {
        result
        output
        evidence {
          current
          expected
        }
      }
    }
"""

# Map fixture filename patterns to (rego_file, native_type, expected_result)
TESTS = [
    # Service key rotation (90 days)
    ("user_service_key_pass.json", "rego/aws_service_access_key_rotation.rego", "user", "pass"),
    ("user_service_key_fail.json", "rego/aws_service_access_key_rotation.rego", "user", "fail"),
    ("user_service_key_skip.json", "rego/aws_service_access_key_rotation.rego", "user", "skip"),
    # Service key warning (85 days)
    ("user_service_key_warning_pass.json", "rego/aws_service_access_key_rotation_warning.rego", "user", "pass"),
    ("user_service_key_warning_fail.json", "rego/aws_service_access_key_rotation_warning.rego", "user", "fail"),
    ("user_service_key_warning_skip.json", "rego/aws_service_access_key_rotation_warning.rego", "user", "skip"),
    # Vendor key rotation (60 days)
    ("user_vendor_key_pass.json", "rego/aws_vendor_access_key_rotation.rego", "user", "pass"),
    ("user_vendor_key_fail.json", "rego/aws_vendor_access_key_rotation.rego", "user", "fail"),
    ("user_vendor_key_skip.json", "rego/aws_vendor_access_key_rotation.rego", "user", "skip"),
    # Vendor key warning (55 days)
    ("user_vendor_key_warning_pass.json", "rego/aws_vendor_access_key_rotation_warning.rego", "user", "pass"),
    ("user_vendor_key_warning_fail.json", "rego/aws_vendor_access_key_rotation_warning.rego", "user", "fail"),
    ("user_vendor_key_warning_skip.json", "rego/aws_vendor_access_key_rotation_warning.rego", "user", "skip"),
    # User key rotation (30 days)
    ("user_user_key_pass.json", "rego/aws_user_access_key_rotation.rego", "user", "pass"),
    ("user_user_key_fail.json", "rego/aws_user_access_key_rotation.rego", "user", "fail"),
    ("user_user_key_skip.json", "rego/aws_user_access_key_rotation.rego", "user", "skip"),
    # User key warning (25 days)
    ("user_user_key_warning_pass.json", "rego/aws_user_access_key_rotation_warning.rego", "user", "pass"),
    ("user_user_key_warning_fail.json", "rego/aws_user_access_key_rotation_warning.rego", "user", "fail"),
    ("user_user_key_warning_skip.json", "rego/aws_user_access_key_rotation_warning.rego", "user", "skip"),
    # Untagged key rotation (30 days)
    ("user_untagged_key_pass.json", "rego/aws_untagged_access_key_rotation.rego", "user", "pass"),
    ("user_untagged_key_fail.json", "rego/aws_untagged_access_key_rotation.rego", "user", "fail"),
    ("user_untagged_key_skip.json", "rego/aws_untagged_access_key_rotation.rego", "user", "skip"),
    # Untagged key warning (25 days)
    ("user_untagged_key_warning_pass.json", "rego/aws_untagged_access_key_rotation_warning.rego", "user", "pass"),
    ("user_untagged_key_warning_fail.json", "rego/aws_untagged_access_key_rotation_warning.rego", "user", "fail"),
    ("user_untagged_key_warning_skip.json", "rego/aws_untagged_access_key_rotation_warning.rego", "user", "skip"),
    # Missing type tag
    ("user_type_tag_pass.json", "rego/aws_missing_type_tag.rego", "user", "pass"),
    ("user_type_tag_fail.json", "rego/aws_missing_type_tag.rego", "user", "fail"),
    ("user_type_tag_fail_bad_value.json", "rego/aws_missing_type_tag.rego", "user", "fail"),
    # Support role missing type tag
    ("role_support_no_type_tag.json", "rego/aws_support_role_missing_type_tag.rego", "role", "fail"),
    ("role_support_valid_type_tag.json", "rego/aws_support_role_missing_type_tag.rego", "role", "pass"),
    ("role_support_bad_type_tag.json", "rego/aws_support_role_missing_type_tag.rego", "role", "fail"),
    ("role_not_support.json", "rego/aws_support_role_missing_type_tag.rego", "role", "skip"),
    # Vendor role missing type tag
    ("role_vendor_no_type_tag.json", "rego/aws_vendor_role_missing_type_tag.rego", "role", "fail"),
    ("role_vendor_valid_type_tag.json", "rego/aws_vendor_role_missing_type_tag.rego", "role", "pass"),
    ("role_vendor_bad_type_tag.json", "rego/aws_vendor_role_missing_type_tag.rego", "role", "fail"),
    ("role_not_vendor.json", "rego/aws_vendor_role_missing_type_tag.rego", "role", "skip"),
    # Service role missing type tag
    ("role_service_no_type_tag.json", "rego/aws_service_role_missing_type_tag.rego", "role", "fail"),
    ("role_service_valid_type_tag.json", "rego/aws_service_role_missing_type_tag.rego", "role", "pass"),
    ("role_service_bad_type_tag.json", "rego/aws_service_role_missing_type_tag.rego", "role", "fail"),
    ("role_not_service.json", "rego/aws_service_role_missing_type_tag.rego", "role", "skip"),
    # Snapshot untrusted sharing
    ("snapshot_sharing_pass.json", "rego/aws_snapshot_untrusted_sharing.rego", "ec2#unencryptedsnapshot", "pass"),
    ("snapshot_sharing_fail_public.json", "rego/aws_snapshot_untrusted_sharing.rego", "ec2#unencryptedsnapshot", "fail"),
    ("snapshot_sharing_fail_untrusted.json", "rego/aws_snapshot_untrusted_sharing.rego", "ec2#encryptedsnapshot", "fail"),
    ("snapshot_sharing_pass_trusted.json", "rego/aws_snapshot_untrusted_sharing.rego", "ec2#encryptedsnapshot", "pass"),
    # Root account usage
    ("rootuser_pass.json", "rego/aws_root_account_usage.rego", "rootUser", "pass"),
    ("rootuser_fail.json", "rego/aws_root_account_usage.rego", "rootUser", "fail"),
    ("rootuser_skip.json", "rego/aws_root_account_usage.rego", "rootUser", "skip"),
    # Classified bucket encryption
    ("bucket_classified_encryption_pass.json", "rego/aws_s3_classified_bucket_encryption.rego", "bucket", "pass"),
    ("bucket_classified_encryption_fail.json", "rego/aws_s3_classified_bucket_encryption.rego", "bucket", "fail"),
    ("bucket_classified_encryption_skip.json", "rego/aws_s3_classified_bucket_encryption.rego", "bucket", "skip"),
    # RDS backup retention
    ("rds_backup_pass.json", "rego/aws_rds_backup_retention.rego", "rds/PostgreSQL/instance", "pass"),
    ("rds_backup_fail.json", "rego/aws_rds_backup_retention.rego", "rds/PostgreSQL/instance", "fail"),
    ("rds_backup_skip.json", "rego/aws_rds_backup_retention.rego", "rds/PostgreSQL/instance", "skip"),
    # KMS key expiration
    ("kms_expiration_pass.json", "rego/aws_kms_key_expiration.rego", "encryptionKey", "pass"),
    ("kms_expiration_fail.json", "rego/aws_kms_key_expiration.rego", "encryptionKey", "fail"),
    ("kms_expiration_skip.json", "rego/aws_kms_key_expiration.rego", "encryptionKey", "skip"),
    # KMS key rotation warning
    ("kms_rotation_pass.json", "rego/aws_kms_key_rotation_warning.rego", "encryptionKey", "pass"),
    ("kms_rotation_fail.json", "rego/aws_kms_key_rotation_warning.rego", "encryptionKey", "fail"),
    ("kms_rotation_skip.json", "rego/aws_kms_key_rotation_warning.rego", "encryptionKey", "skip"),
    # AMI untrusted sharing
    ("ami_sharing_pass.json", "rego/aws_ami_untrusted_sharing.rego", "ami", "pass"),
    ("ami_sharing_pass_trusted.json", "rego/aws_ami_untrusted_sharing.rego", "ami", "pass"),
    ("ami_sharing_fail_public.json", "rego/aws_ami_untrusted_sharing.rego", "ami", "fail"),
    ("ami_sharing_fail_untrusted.json", "rego/aws_ami_untrusted_sharing.rego", "ami", "fail"),
    # RDS snapshot untrusted sharing
    ("rds_snapshot_sharing_pass.json", "rego/aws_rds_snapshot_untrusted_sharing.rego", "rds#snapshot", "pass"),
    ("rds_snapshot_sharing_pass_trusted.json", "rego/aws_rds_snapshot_untrusted_sharing.rego", "rds#snapshot", "pass"),
    ("rds_snapshot_sharing_fail_public.json", "rego/aws_rds_snapshot_untrusted_sharing.rego", "rds#snapshot", "fail"),
    ("rds_snapshot_sharing_fail_untrusted.json", "rego/aws_rds_snapshot_untrusted_sharing.rego", "rds#snapshot", "fail"),
    # S3 bucket untrusted sharing
    ("bucket_sharing_pass.json", "rego/aws_s3_bucket_untrusted_sharing.rego", "bucket", "pass"),
    ("bucket_sharing_fail_public_policy.json", "rego/aws_s3_bucket_untrusted_sharing.rego", "bucket", "fail"),
    ("bucket_sharing_fail_untrusted_policy.json", "rego/aws_s3_bucket_untrusted_sharing.rego", "bucket", "fail"),
    ("bucket_sharing_fail_public_acl.json", "rego/aws_s3_bucket_untrusted_sharing.rego", "bucket", "fail"),
    ("bucket_sharing_fail_inventory.json", "rego/aws_s3_bucket_untrusted_sharing.rego", "bucket", "fail"),
    ("bucket_sharing_pass_trusted_policy.json", "rego/aws_s3_bucket_untrusted_sharing.rego", "bucket", "pass"),
    # Deploy role missing type tag
    ("role_deploy_no_type_tag.json", "rego/aws_deploy_role_missing_type_tag.rego", "role", "fail"),
    ("role_deploy_valid_type_tag.json", "rego/aws_deploy_role_missing_type_tag.rego", "role", "pass"),
    ("role_deploy_bad_type_tag.json", "rego/aws_deploy_role_missing_type_tag.rego", "role", "fail"),
    ("role_not_deploy.json", "rego/aws_deploy_role_missing_type_tag.rego", "role", "skip"),
    # Consumer role missing type tag
    ("role_consumer_no_type_tag.json", "rego/aws_consumer_role_missing_type_tag.rego", "role", "fail"),
    ("role_consumer_valid_type_tag.json", "rego/aws_consumer_role_missing_type_tag.rego", "role", "pass"),
    ("role_consumer_bad_type_tag.json", "rego/aws_consumer_role_missing_type_tag.rego", "role", "fail"),
    ("role_not_consumer.json", "rego/aws_consumer_role_missing_type_tag.rego", "role", "skip"),
    # Vendor role auto-tag based on trust relationship
    ("role_vendor_auto_tag_fail.json", "rego/aws_vendor_role_auto_tag.rego", "role", "fail"),
    ("role_vendor_auto_tag_pass.json", "rego/aws_vendor_role_auto_tag.rego", "role", "pass"),
    ("role_vendor_auto_tag_skip.json", "rego/aws_vendor_role_auto_tag.rego", "role", "skip"),
    ("role_vendor_auto_tag_skip_internal.json", "rego/aws_vendor_role_auto_tag.rego", "role", "skip"),
    # IAM user AWS managed policy
    ("user_aws_managed_policy_fail.json", "rego/aws_user_aws_managed_policy.rego", "user", "fail"),
    ("user_aws_managed_policy_pass.json", "rego/aws_user_aws_managed_policy.rego", "user", "pass"),
    ("user_aws_managed_policy_pass_none.json", "rego/aws_user_aws_managed_policy.rego", "user", "pass"),
    # IAM role untrusted trust
    ("role_trust_pass.json", "rego/aws_role_untrusted_trust.rego", "role", "pass"),
    ("role_trust_fail_untrusted.json", "rego/aws_role_untrusted_trust.rego", "role", "fail"),
    ("role_trust_fail_public.json", "rego/aws_role_untrusted_trust.rego", "role", "fail"),
    ("role_trust_skip.json", "rego/aws_role_untrusted_trust.rego", "role", "skip"),
    # API Gateway no authorization
    ("apigateway_no_auth_fail.json", "rego/aws_apigateway_no_authorization.rego", "apiGateway", "fail"),
    ("apigateway_no_auth_pass.json", "rego/aws_apigateway_no_authorization.rego", "apiGateway", "pass"),
    ("apigateway_no_auth_skip.json", "rego/aws_apigateway_no_authorization.rego", "apiGateway", "skip"),
]


def pad_base64(data):
    missing_padding = len(data) % 4
    if missing_padding != 0:
        data += "=" * (4 - missing_padding)
    return data


def get_token(client_id, client_secret):
    auth_payload = {
        "grant_type": "client_credentials",
        "audience": "wiz-api",
        "client_id": client_id,
        "client_secret": client_secret,
    }
    response = requests.post(
        url="https://auth.app.wiz.io/oauth/token",
        headers=HEADERS_AUTH,
        data=auth_payload,
        timeout=180,
    )
    response.raise_for_status()
    response_json = response.json()
    token = response_json.get("access_token")
    if not token:
        raise ValueError(f"Could not retrieve token: {response_json.get('message')}")
    payload = json.loads(base64.standard_b64decode(pad_base64(token.split(".")[1])))
    return token, payload["dc"]


def run_json_test(dc, rule_code, input_json):
    variables = {
        "rule": rule_code,
        "json": input_json,
    }
    response = requests.post(
        url=f"https://api.{dc}.app.wiz.io/graphql",
        json={"variables": variables, "query": QUERY_JSON},
        headers=HEADERS,
        timeout=180,
    )
    response.raise_for_status()
    data = response.json()
    test = data.get("data", {}).get("cloudConfigurationRuleJsonTest")
    if not test:
        errors = data.get("errors", [])
        return None, errors
    # API returns "passed"/"failed"/"skipped" — normalize to "pass"/"fail"/"skip"
    raw = test.get("result", "").lower()
    normalized = raw.rstrip("ed") if raw.endswith("ed") else raw
    # Handle "passed" -> "pass" (not "pass" -> "pa")
    result_map = {"passed": "pass", "failed": "fail", "skipped": "skip"}
    return result_map.get(raw, raw), None


def main():
    client_id = os.environ.get("WIZ_CLIENT_ID")
    client_secret = os.environ.get("WIZ_CLIENT_SECRET")
    if not client_id or not client_secret:
        print("Error: WIZ_CLIENT_ID and WIZ_CLIENT_SECRET must be set.")
        sys.exit(1)

    print("Authenticating...")
    token, dc = get_token(client_id, client_secret)
    HEADERS["Authorization"] = f"Bearer {token}"

    # Cache loaded rego files
    rego_cache = {}
    passed = 0
    failed = 0
    errors = 0

    print(f"\nRunning {len(TESTS)} tests...\n")

    for fixture_name, rego_path, native_type, expected in TESTS:
        fixture_path = f"tests/fixtures/{fixture_name}"

        # Load fixture
        if not os.path.exists(fixture_path):
            print(f"  \033[33mMISSING\033[0m  {fixture_name} (file not found)")
            errors += 1
            continue

        with open(fixture_path) as f:
            input_json = json.load(f)

        # Load rego (cached)
        if rego_path not in rego_cache:
            with open(rego_path) as f:
                rego_cache[rego_path] = f.read()

        # Run test
        actual, api_errors = run_json_test(dc, rego_cache[rego_path], input_json)

        if api_errors:
            print(f"  \033[31mERROR\033[0m    {fixture_name} → API error: {api_errors[0].get('message', '')[:80]}")
            errors += 1
            continue

        if actual == expected:
            print(f"  \033[32m✓ PASS\033[0m   {fixture_name} → {actual}")
            passed += 1
        else:
            print(f"  \033[31m✗ FAIL\033[0m   {fixture_name} → expected {expected}, got {actual}")
            failed += 1

    print(f"\n{'='*60}")
    print(f"Results: {passed} passed, {failed} failed, {errors} errors out of {len(TESTS)} tests")

    if failed > 0 or errors > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
