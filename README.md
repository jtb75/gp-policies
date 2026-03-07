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
├── tests/
│   ├── test_ccr.py                          # Test a single rule against a fixture or live resources
│   ├── validate_fixtures.py                 # Run all fixtures against their rules (full test suite)
│   ├── fetch_fixtures.py                    # Fetch real resource JSONs from Wiz to use as fixtures
│   └── fixtures/                            # Mock resource JSON files for controlled testing
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

## Testing Rules

The test script (`tests/test_ccr.py`) validates rules using the Wiz GraphQL API. It supports two modes:

### Test Against Mock JSON (Recommended for Development)

Use `--input` to test a rule against a local JSON fixture. This uses the `cloudConfigurationRuleJsonTest` API endpoint, which evaluates instantly without waiting for globals propagation.

```bash
source .env

# Test a rule against a specific fixture
python tests/test_ccr.py rego/aws_support_role_missing_type_tag.rego role \
  --input tests/fixtures/role_support_no_type_tag.json
```

Each rule has fixtures for pass, fail, and skip (where applicable). Fixture names follow the pattern `<type>_<rule>_<outcome>.json`.

### Run the Full Test Suite

Validate all fixtures against their rules in one command:

```bash
source .env
python tests/validate_fixtures.py
```

This runs all 41 fixture/rule combinations and reports pass/fail. When adding a new rule, add its test cases to `validate_fixtures.py` in the `TESTS` list.

### Fetch Real Resource JSON for Fixtures

Use the fixture fetcher to download real resource JSONs from the Wiz Graph API:

```bash
source .env

# Fetch 3 role resources
python tests/fetch_fixtures.py role --count 3

# Fetch snapshot resources
python tests/fetch_fixtures.py "ec2#unencryptedsnapshot" --count 2
```

This uses a two-step approach: `graphSearch` to find entity IDs, then `graphEntity` with `providerData` to get the raw cloud resource JSON. Downloaded fixtures can be modified to create pass/fail/skip variants.

### Test Against Live Resources

Omit `--input` to evaluate the rule against real cloud resources:

```bash
# Test against up to 500 live resources
python tests/test_ccr.py rego/aws_missing_type_tag.rego user --first 500

# Scope to specific accounts
python tests/test_ccr.py rego/aws_snapshot_untrusted_sharing.rego ec2#unencryptedsnapshot \
  --accounts <account-uuid>
```

**Note:** After deploying changes to the globals package via Terraform, allow up to 30 minutes for Wiz to propagate the updates before testing against live resources. The JSON test mode (`--input`) is not affected by this delay.

## Adding a New Rule

See [docs/creating-rules.md](docs/creating-rules.md) for a step-by-step guide on creating new CCRs.
