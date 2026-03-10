# Rules Reference

Complete list of all Wiz Cloud Configuration Rules (CCRs) managed in this repository. Each rule has a Terraform definition (`.tf`), a Rego policy (`.rego`), and test fixtures in `tests/fixtures/`.

## Access Key Rotation

Rules are applied based on the IAM user's `type` tag value. Each type has a hard-limit rule (HIGH severity) and an early-warning rule (INFORMATIONAL severity).

| Type Tag Value | Hard Limit | Warning | Filter |
|----------------|-----------|---------|--------|
| `service` | 90 days | 85 days | Tag `type=service` |
| `vendor` | 60 days | 55 days | Tag `type=vendor` |
| `user` | 30 days | 25 days | Tag `type=user` |
| Missing/unknown | 30 days | 25 days | No `type` tag or unrecognized value |

All thresholds are centralized in `rego/packages/jtb75_globals.rego` and can be adjusted without modifying individual rules.

### Service Access Key Rotation (90 days)

| | |
|---|---|
| **Terraform** | `aws_access_key_rotation.tf` |
| **Rego** | `rego/aws_service_access_key_rotation.rego` |
| **Native Type** | `user` |
| **Severity** | HIGH |
| **Globals** | `service_key_max_age_days` |

Fails IAM users tagged `type=service` with an active access key older than 90 days. Skips users without the `service` tag.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `user_service_key_pass.json` | PASS — key rotated within 90 days |
| `user_service_key_fail.json` | FAIL — key older than 90 days |
| `user_service_key_skip.json` | SKIP — user has `type=user` tag |

### Service Access Key Warning (85 days)

| | |
|---|---|
| **Terraform** | `aws_access_key_rotation_warning.tf` |
| **Rego** | `rego/aws_service_access_key_rotation_warning.rego` |
| **Native Type** | `user` |
| **Severity** | INFORMATIONAL |
| **Globals** | `service_key_warning_days` |

Same logic as above but triggers at 85 days as an early warning.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `user_service_key_warning_pass.json` | PASS — key rotated within 85 days |
| `user_service_key_warning_fail.json` | FAIL — key older than 85 days |
| `user_service_key_warning_skip.json` | SKIP — user has `type=vendor` tag |

### Vendor Access Key Rotation (60 days)

| | |
|---|---|
| **Terraform** | `aws_vendor_access_key_rotation.tf` |
| **Rego** | `rego/aws_vendor_access_key_rotation.rego` |
| **Native Type** | `user` |
| **Severity** | HIGH |
| **Globals** | `vendor_key_max_age_days` |

Fails IAM users tagged `type=vendor` with an active access key older than 60 days.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `user_vendor_key_pass.json` | PASS — key rotated within 60 days |
| `user_vendor_key_fail.json` | FAIL — key older than 60 days |
| `user_vendor_key_skip.json` | SKIP — user has `type=service` tag |

### Vendor Access Key Warning (55 days)

| | |
|---|---|
| **Terraform** | `aws_vendor_access_key_rotation_warning.tf` |
| **Rego** | `rego/aws_vendor_access_key_rotation_warning.rego` |
| **Native Type** | `user` |
| **Severity** | INFORMATIONAL |
| **Globals** | `vendor_key_warning_days` |

Same logic as above but triggers at 55 days as an early warning.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `user_vendor_key_warning_pass.json` | PASS — key rotated within 55 days |
| `user_vendor_key_warning_fail.json` | FAIL — key older than 55 days |
| `user_vendor_key_warning_skip.json` | SKIP — user has `type=user` tag |

### User Access Key Rotation (30 days)

| | |
|---|---|
| **Terraform** | `aws_user_access_key_rotation.tf` |
| **Rego** | `rego/aws_user_access_key_rotation.rego` |
| **Native Type** | `user` |
| **Severity** | HIGH |
| **Globals** | `user_key_max_age_days` |

Fails IAM users tagged `type=user` with an active access key older than 30 days.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `user_user_key_pass.json` | PASS — key rotated within 30 days |
| `user_user_key_fail.json` | FAIL — key older than 30 days |
| `user_user_key_skip.json` | SKIP — user has `type=service` tag |

### User Access Key Warning (25 days)

| | |
|---|---|
| **Terraform** | `aws_user_access_key_rotation_warning.tf` |
| **Rego** | `rego/aws_user_access_key_rotation_warning.rego` |
| **Native Type** | `user` |
| **Severity** | INFORMATIONAL |
| **Globals** | `user_key_warning_days` |

Same logic as above but triggers at 25 days as an early warning.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `user_user_key_warning_pass.json` | PASS — key rotated within 25 days |
| `user_user_key_warning_fail.json` | FAIL — key older than 25 days |
| `user_user_key_warning_skip.json` | SKIP — user has `type=vendor` tag |

### Untagged Access Key Rotation (30 days)

| | |
|---|---|
| **Terraform** | `aws_untagged_access_key_rotation.tf` |
| **Rego** | `rego/aws_untagged_access_key_rotation.rego` |
| **Native Type** | `user` |
| **Severity** | HIGH |
| **Globals** | `user_key_max_age_days` |

Catchall rule for IAM users without a recognized `type` tag (missing tag or unrecognized value). Uses the same 30-day threshold as human users. Skips users that have a recognized type tag (`user`, `service`, or `vendor`).

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `user_untagged_key_pass.json` | PASS — no type tag, key rotated within 30 days |
| `user_untagged_key_fail.json` | FAIL — no type tag, key older than 30 days |
| `user_untagged_key_skip.json` | SKIP — user has `type=service` tag |

### Untagged Access Key Warning (25 days)

| | |
|---|---|
| **Terraform** | `aws_untagged_access_key_rotation_warning.tf` |
| **Rego** | `rego/aws_untagged_access_key_rotation_warning.rego` |
| **Native Type** | `user` |
| **Severity** | INFORMATIONAL |
| **Globals** | `user_key_warning_days` |

Same logic as above but triggers at 25 days as an early warning.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `user_untagged_key_warning_pass.json` | PASS — `type=unknown` tag, key within 25 days |
| `user_untagged_key_warning_fail.json` | FAIL — `type=unknown` tag, key older than 25 days |
| `user_untagged_key_warning_skip.json` | SKIP — user has `type=user` tag |

## Tag Enforcement

### IAM Users Must Have a Valid Type Tag

| | |
|---|---|
| **Terraform** | `aws_missing_type_tag.tf` |
| **Rego** | `rego/aws_missing_type_tag.rego` |
| **Native Type** | `user` |
| **Severity** | HIGH |

Fails any IAM user missing a `type` tag or with an unrecognized value. No skip condition — all IAM users are evaluated.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `user_type_tag_pass.json` | PASS — has `type=service` tag |
| `user_type_tag_fail.json` | FAIL — no type tag |
| `user_type_tag_fail_bad_value.json` | FAIL — `type=unknown` (unrecognized) |

### Support Roles Must Have a Valid Type Tag

| | |
|---|---|
| **Terraform** | `aws_support_role_missing_type_tag.tf` |
| **Rego** | `rego/aws_support_role_missing_type_tag.rego` |
| **Native Type** | `role` |
| **Severity** | HIGH |
| **Globals** | `kbs_support_roles` |

Fails IAM roles matching names in `kbs_support_roles` that are missing a `type` tag or have an unrecognized value. Skips roles not in the list.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `role_support_valid_type_tag.json` | PASS — KBSSupportRole with `type=service` |
| `role_support_no_type_tag.json` | FAIL — Webserver-Role with no type tag |
| `role_support_bad_type_tag.json` | FAIL — KBSSupportAdmin with `type=unknown` |
| `role_not_support.json` | SKIP — role name not in list |

### Vendor Roles Must Have a Valid Type Tag

| | |
|---|---|
| **Terraform** | `aws_vendor_role_missing_type_tag.tf` |
| **Rego** | `rego/aws_vendor_role_missing_type_tag.rego` |
| **Native Type** | `role` |
| **Severity** | HIGH |
| **Globals** | `kbs_vendor_roles` |

Fails IAM roles matching names in `kbs_vendor_roles` that are missing a `type` tag or have an unrecognized value. Skips roles not in the list.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `role_vendor_valid_type_tag.json` | PASS — VendorBackupAgent with `type=vendor` |
| `role_vendor_no_type_tag.json` | FAIL — VendorMonitoringRole with no type tag |
| `role_vendor_bad_type_tag.json` | FAIL — ThirdPartyAuditRole with `type=unknown` |
| `role_not_vendor.json` | SKIP — role name not in list |

### Service Roles Must Have a Valid Type Tag

| | |
|---|---|
| **Terraform** | `aws_service_role_missing_type_tag.tf` |
| **Rego** | `rego/aws_service_role_missing_type_tag.rego` |
| **Native Type** | `role` |
| **Severity** | HIGH |
| **Globals** | `kbs_service_roles` |

Fails IAM roles matching names in `kbs_service_roles` that are missing a `type` tag or have an unrecognized value. Skips roles not in the list.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `role_service_valid_type_tag.json` | PASS — DataPipelineExecutor with `type=service` |
| `role_service_no_type_tag.json` | FAIL — AppDeploymentRole with no type tag |
| `role_service_bad_type_tag.json` | FAIL — CICDServiceRole with `type=unknown` |
| `role_not_service.json` | SKIP — role name not in list |

### Consumer Role Missing Type Tag

| | |
|---|---|
| **Terraform** | `aws_consumer_role_missing_type_tag.tf` |
| **Rego** | `rego/aws_consumer_role_missing_type_tag.rego` |
| **Native Type** | `role` |
| **Severity** | HIGH |
| **Globals** | None |

Fails IAM roles with "consumer" in their name (case-insensitive) that are missing a `type:consumer` tag or have a different type tag value. Skips roles without "consumer" in the name.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `role_consumer_valid_type_tag.json` | PASS — EventConsumerProcessor with `type=consumer` |
| `role_consumer_no_type_tag.json` | FAIL — DataConsumerReadOnly with no type tag |
| `role_consumer_bad_type_tag.json` | FAIL — QueueConsumerRole with `type=service` |
| `role_not_consumer.json` | SKIP — role name doesn't contain "consumer" |

### Vendor Role Auto-Tag (Trust-Based Detection)

| | |
|---|---|
| **Terraform** | `aws_vendor_role_auto_tag.tf` |
| **Rego** | `rego/aws_vendor_role_auto_tag.rego` |
| **Native Type** | `role` |
| **Severity** | INFORMATIONAL |
| **Globals** | `trusted_external_accounts` |

Dynamically identifies vendor roles by their trust relationships rather than a hardcoded name list. Fails if a role trusts an account in `trusted_external_accounts` but is missing a `type:vendor` tag. Skips roles that only trust AWS services, federated providers, or internal accounts.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `role_vendor_auto_tag_pass.json` | PASS — trusts external account, has type:vendor tag |
| `role_vendor_auto_tag_fail.json` | FAIL — trusts external account, missing type:vendor tag |
| `role_vendor_auto_tag_skip.json` | SKIP — only trusts AWS service (Lambda) |
| `role_vendor_auto_tag_skip_internal.json` | SKIP — trusts internal account only |

## Untrusted Account Sharing

### EC2 Snapshots Shared with Untrusted Accounts

| | |
|---|---|
| **Terraform** | `aws_snapshot_untrusted_sharing.tf` |
| **Rego** | `rego/aws_snapshot_untrusted_sharing.rego` |
| **Native Types** | `ec2#encryptedsnapshot`, `ec2#unencryptedsnapshot` |
| **Severity** | HIGH |
| **Globals** | `trusted_internal_accounts`, `trusted_external_accounts` |

Fails if a snapshot's `CreateVolumePermissions` includes a public group (`"all"`) or an account not in either trusted list. No skip condition — all snapshots are evaluated.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `snapshot_sharing_pass.json` | PASS — no sharing permissions |
| `snapshot_sharing_pass_trusted.json` | PASS — shared with trusted external account |
| `snapshot_sharing_fail_public.json` | FAIL — shared publicly (Group: "all") |
| `snapshot_sharing_fail_untrusted.json` | FAIL — shared with untrusted account |

### EC2 AMIs Shared with Untrusted Accounts

| | |
|---|---|
| **Terraform** | `aws_ami_untrusted_sharing.tf` |
| **Rego** | `rego/aws_ami_untrusted_sharing.rego` |
| **Native Type** | `ami` |
| **Severity** | HIGH |
| **Globals** | `trusted_internal_accounts`, `trusted_external_accounts` |

Fails if an AMI is public (`Public: true` or `LaunchPermissions` contains `Group: "all"`) or shared with an account not in either trusted list. No skip condition — all AMIs are evaluated.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `ami_sharing_pass.json` | PASS — private, no LaunchPermissions |
| `ami_sharing_pass_trusted.json` | PASS — shared with trusted external account |
| `ami_sharing_fail_public.json` | FAIL — public AMI |
| `ami_sharing_fail_untrusted.json` | FAIL — shared with untrusted account |

### RDS Snapshots Shared with Untrusted Accounts

| | |
|---|---|
| **Terraform** | `aws_rds_snapshot_untrusted_sharing.tf` |
| **Rego** | `rego/aws_rds_snapshot_untrusted_sharing.rego` |
| **Native Types** | `rds#snapshot`, `rds#clustersnapshot` |
| **Severity** | HIGH |
| **Globals** | `trusted_internal_accounts`, `trusted_external_accounts` |

Fails if an RDS snapshot's `SharedAccounts` contains `"all"` (public) or an account not in either trusted list. No skip condition — all RDS snapshots are evaluated.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `rds_snapshot_sharing_pass.json` | PASS — no sharing (SharedAccounts is null) |
| `rds_snapshot_sharing_pass_trusted.json` | PASS — shared with trusted external account |
| `rds_snapshot_sharing_fail_public.json` | FAIL — shared publicly (SharedAccounts contains "all") |
| `rds_snapshot_sharing_fail_untrusted.json` | FAIL — shared with untrusted account |

### S3 Buckets Shared with Untrusted Accounts

| | |
|---|---|
| **Terraform** | `aws_s3_bucket_untrusted_sharing.tf` |
| **Rego** | `rego/aws_s3_bucket_untrusted_sharing.rego` |
| **Native Type** | `bucket` |
| **Severity** | HIGH |
| **Globals** | `trusted_internal_accounts`, `trusted_external_accounts` |

Checks three sharing vectors:
1. **Bucket policy** — principals referencing untrusted accounts or wildcard (`*`)
2. **ACL grants** — public access URIs (AllUsers, AuthenticatedUsers)
3. **Inventory configurations** — destination accounts not in trusted lists

The bucket's own account (from `WizMetadata.accountId`) is always considered trusted. No skip condition.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `bucket_sharing_pass.json` | PASS — no sharing, owner-only ACL |
| `bucket_sharing_pass_trusted_policy.json` | PASS — policy allows trusted external account |
| `bucket_sharing_fail_public_policy.json` | FAIL — policy allows Principal: "*" |
| `bucket_sharing_fail_untrusted_policy.json` | FAIL — policy allows untrusted account |
| `bucket_sharing_fail_public_acl.json` | FAIL — ACL grants AllUsers access |
| `bucket_sharing_fail_inventory.json` | FAIL — inventory destination is untrusted |

### IAM Roles with Untrusted Account Trust Relationships

| | |
|---|---|
| **Terraform** | `aws_role_untrusted_trust.tf` |
| **Rego** | `rego/aws_role_untrusted_trust.rego` |
| **Native Type** | `role` |
| **Severity** | HIGH |
| **Globals** | `trusted_internal_accounts`, `trusted_external_accounts` |

Fails if an IAM role's trust policy (`AssumeRolePolicyDocument`) allows assumption by `"*"` (any AWS account) or by an account not in either trusted list. Skips roles that only trust AWS services or federated providers (no cross-account AWS principals).

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `role_trust_pass.json` | PASS — trusts account in trusted internal list |
| `role_trust_fail_untrusted.json` | FAIL — trusts account not in any trusted list |
| `role_trust_fail_public.json` | FAIL — trusts `"*"` (any AWS account) |
| `role_trust_skip.json` | SKIP — only trusts AWS service (no cross-account) |

## Root Account Usage

### Root Account Used in the Last Day

| | |
|---|---|
| **Terraform** | `aws_root_account_usage.tf` |
| **Rego** | `rego/aws_root_account_usage.rego` |
| **Native Type** | `rootUser` |
| **Severity** | HIGH |
| **Globals** | `account_min_age_days`, `root_usage_lookback_days` |

Fails if an AWS root account has been used (password login or access key) within the lookback window (default 1 day). Accounts younger than the minimum age threshold (default 15 days) are skipped to allow the cloud platform team time to set up automation.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `rootuser_pass.json` | PASS — old account, root not used recently |
| `rootuser_fail.json` | FAIL — old account, root used today |
| `rootuser_skip.json` | SKIP — account younger than 15 days |

## Data Protection

### Classified S3 Buckets Must Be Encrypted

| | |
|---|---|
| **Terraform** | `aws_s3_classified_bucket_encryption.tf` |
| **Rego** | `rego/aws_s3_classified_bucket_encryption.rego` |
| **Native Type** | `bucket` |
| **Severity** | HIGH |

Fails if an S3 bucket tagged with `data-classification` of `confidential` or `highly-confidential` does not have server-side encryption configured. Buckets without a classified tag (or with other values like `public`) are skipped.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `bucket_classified_encryption_pass.json` | PASS — confidential bucket with KMS encryption |
| `bucket_classified_encryption_fail.json` | FAIL — highly-confidential bucket with no encryption |
| `bucket_classified_encryption_skip.json` | SKIP — bucket tagged as public |

## Database Configuration

### RDS Backup Retention Period

| | |
|---|---|
| **Terraform** | `aws_rds_backup_retention.tf` |
| **Rego** | `rego/aws_rds_backup_retention.rego` |
| **Native Types** | All RDS instance types (Aurora, PostgreSQL, MySQL, MariaDB, MSSQL, Oracle, Neptune, DocDB) |
| **Severity** | HIGH |
| **Globals** | `rds_backup_retention_days` |

Fails if an RDS database instance has a `BackupRetentionPeriod` below the required threshold (default 35 days, per GP DBA team standards). Read replicas are skipped.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `rds_backup_pass.json` | PASS — 35-day retention period |
| `rds_backup_fail.json` | FAIL — 7-day retention period |
| `rds_backup_skip.json` | SKIP — read replica |

## KMS Key Management

### KMS Imported Key Material Expiring Soon

| | |
|---|---|
| **Terraform** | `aws_kms_key_expiration.tf` |
| **Rego** | `rego/aws_kms_key_expiration.rego` |
| **Native Type** | `encryptionKey` |
| **Severity** | HIGH |
| **Globals** | `kms_expiration_warning_days` |

Fails if a KMS key with imported key material (`Origin: "EXTERNAL"`) has a `ValidTo` date within the warning threshold (default 5 days). Skips AWS-generated keys (no expiration) and disabled keys.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `kms_expiration_pass.json` | PASS — imported key, expires far in the future |
| `kms_expiration_fail.json` | FAIL — imported key, expires within 5 days |
| `kms_expiration_skip.json` | SKIP — AWS-generated key (ValidTo is null) |

### KMS Key Rotation Approaching

| | |
|---|---|
| **Terraform** | `aws_kms_key_rotation_warning.tf` |
| **Rego** | `rego/aws_kms_key_rotation_warning.rego` |
| **Native Type** | `encryptionKey` |
| **Severity** | INFORMATIONAL |
| **Globals** | `kms_rotation_warning_days` |

Fails if a KMS key's scheduled automatic rotation (`NextRotationDate`) is within the warning threshold (default 5 days). Skips keys without rotation enabled.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `kms_rotation_pass.json` | PASS — rotation scheduled far in the future |
| `kms_rotation_fail.json` | FAIL — rotation scheduled within 5 days |
| `kms_rotation_skip.json` | SKIP — rotation not enabled |

## IAM Policy Hygiene

### IAM Users with AWS Managed Policies

| | |
|---|---|
| **Terraform** | `aws_user_aws_managed_policy.tf` |
| **Rego** | `rego/aws_user_aws_managed_policy.rego` |
| **Native Type** | `user` |
| **Severity** | HIGH |
| **Globals** | None |

Fails if an IAM user has any AWS-managed policy attached (ARN containing `:aws:policy/`). AWS managed policies are overly permissive; users should have customer-managed policies scoped to their specific needs. Passes if only customer-managed policies or no managed policies are attached.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `user_aws_managed_policy_pass.json` | PASS — only customer-managed policy attached |
| `user_aws_managed_policy_pass_none.json` | PASS — no managed policies attached |
| `user_aws_managed_policy_fail.json` | FAIL — AWS managed policies attached |

## API Gateway Security

### API Gateway Methods Without Authorization

| | |
|---|---|
| **Terraform** | `aws_apigateway_no_authorization.tf` |
| **Rego** | `rego/aws_apigateway_no_authorization.rego` |
| **Native Type** | `apiGateway` |
| **Severity** | HIGH |
| **Globals** | None |

Fails if any method on any resource in the API Gateway has `AuthorizationType` set to `NONE`, meaning it accepts unauthenticated requests. Skips APIs tagged with `authentication:kochid`, indicating authentication is handled externally via KochID.

**Fixtures:**

| Fixture | Expected |
|---------|----------|
| `apigateway_no_auth_pass.json` | PASS — all methods have authorization configured |
| `apigateway_no_auth_fail.json` | FAIL — methods with AuthorizationType NONE |
| `apigateway_no_auth_skip.json` | SKIP — has authentication:kochid exemption tag |

## Shared Globals Package

The `wiz_custom_rego_package` resource (`rego/packages/jtb75_globals.rego`) provides shared variables used across multiple rules:

| Variable | Used By |
|----------|---------|
| `trusted_internal_accounts` | Snapshot sharing, S3 sharing |
| `trusted_external_accounts` | Snapshot sharing, S3 sharing |
| `trusted_accounts` | Union of both (available for future rules) |
| `service_key_max_age_days` / `service_key_warning_days` | Service key rotation |
| `user_key_max_age_days` / `user_key_warning_days` | User + untagged key rotation |
| `vendor_key_max_age_days` / `vendor_key_warning_days` | Vendor key rotation |
| `kbs_support_roles` | Support role tag enforcement |
| `kbs_vendor_roles` | Vendor role tag enforcement |
| `kbs_service_roles` | Service role tag enforcement |
| `account_min_age_days` | Root account usage (skip threshold) |
| `root_usage_lookback_days` | Root account usage (alert window) |
| `rds_backup_retention_days` | RDS backup retention |
| `kms_expiration_warning_days` | KMS key expiration warning |
| `kms_rotation_warning_days` | KMS key rotation warning |
