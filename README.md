# GP Policies - Wiz Custom Cloud Configuration Rules

This repository manages custom Wiz Cloud Configuration Rules (CCRs) using the Wiz Terraform provider. All rules are prefixed with `JTB75` for identification within the Wiz portal.

## Repository Structure

```
gp-policies/
├── provider.tf                              # Wiz Terraform provider configuration
├── rego_packages.tf                         # Custom Rego package definitions
├── aws_*.tf                                 # Terraform resource definitions for each CCR
├── rego/
│   ├── packages/
│   │   └── jtb75_globals.rego               # Shared variables (account lists, thresholds, role names)
│   ├── aws_service_access_key_rotation.rego # Service account key rotation (90 days)
│   ├── aws_service_access_key_rotation_warning.rego
│   ├── aws_vendor_access_key_rotation.rego  # Vendor key rotation (60 days)
│   ├── aws_vendor_access_key_rotation_warning.rego
│   ├── aws_user_access_key_rotation.rego    # User key rotation (30 days)
│   ├── aws_user_access_key_rotation_warning.rego
│   ├── aws_untagged_access_key_rotation.rego # Catchall for untagged users (30 days)
│   ├── aws_untagged_access_key_rotation_warning.rego
│   ├── aws_missing_type_tag.rego            # IAM users missing valid type tag
│   ├── aws_support_role_missing_type_tag.rego # Support roles missing valid type tag
│   ├── aws_snapshot_untrusted_sharing.rego  # EC2 snapshots shared with untrusted accounts
│   └── aws_s3_bucket_untrusted_sharing.rego # S3 buckets shared with untrusted accounts
├── .env                                     # Wiz credentials (gitignored)
├── .gitignore
└── .terraform.lock.hcl                      # Provider version lock
```

## Current Rules

### Access Key Rotation

Rules are applied based on the IAM user's `type` tag value. Each type has a hard-limit rule (HIGH severity) and an early-warning rule (INFORMATIONAL severity).

| Type Tag Value | Hard Limit | Warning | Filter |
|----------------|-----------|---------|--------|
| `service` | 90 days | 85 days | Tag `type=service` |
| `vendor` | 60 days | 55 days | Tag `type=vendor` |
| `user` | 30 days | 25 days | Tag `type=user` |
| Missing/unknown | 30 days | 25 days | No `type` tag or unrecognized value |

All thresholds are centralized in `rego/packages/jtb75_globals.rego` and can be adjusted without modifying individual rules.

### Tag Enforcement

| Rule | Description |
|------|-------------|
| IAM users must have a valid type tag | Fails any IAM user missing a `type` tag or with an unrecognized value |
| Support roles must have a valid type tag | Same check, but only for IAM roles matching names in `kbs_support_roles` |

### Untrusted Account Sharing

| Rule | Description |
|------|-------------|
| EC2 snapshots shared with untrusted accounts | Checks `CreateVolumePermissions` for accounts not in trusted lists |
| S3 buckets shared with untrusted accounts | Checks bucket policy principals, ACL grants, and inventory destinations |

Both rules reference `trusted_internal_accounts` and `trusted_external_accounts` from the globals package.

## Shared Globals Package

The `wiz_custom_rego_package` resource (`rego/packages/jtb75_globals.rego`) provides shared variables used across multiple rules:

- **`trusted_internal_accounts`** - AWS accounts in your organization
- **`trusted_external_accounts`** - Approved third-party AWS accounts
- **`trusted_accounts`** - Union of both (for rules that don't need to distinguish)
- **`service_key_max_age_days`** / **`service_key_warning_days`** - Service account thresholds
- **`user_key_max_age_days`** / **`user_key_warning_days`** - Human user thresholds
- **`vendor_key_max_age_days`** / **`vendor_key_warning_days`** - Vendor thresholds
- **`kbs_support_roles`** - Known support role names for tag enforcement

## Setup

### Prerequisites

- Terraform 0.14+
- A Wiz service account with Custom Integration (GraphQL API) type and write permissions

### Authentication

Create a `.env` file (already gitignored):

```bash
export WIZ_CLIENT_ID=your-client-id
export WIZ_CLIENT_SECRET=your-client-secret
```

### Deploy

```bash
source .env
terraform init
terraform plan
terraform apply
```

## Adding a New Rule

See [docs/creating-rules.md](docs/creating-rules.md) for a step-by-step guide on creating new CCRs.
