# GP Policies - Wiz Custom Cloud Configuration Rules

This repository manages custom Wiz Cloud Configuration Rules (CCRs) using the Wiz Terraform provider. All rules are prefixed with `JTB75` for identification within the Wiz portal.

## Repository Structure

```
gp-policies/
├── provider.tf                    # Wiz Terraform provider configuration
├── rego_packages.tf               # Custom Rego package definitions
├── aws_*.tf                       # Terraform resource definitions for each CCR
├── rego/
│   ├── packages/
│   │   └── jtb75_globals.rego     # Shared variables (account lists, thresholds, role names)
│   └── aws_*.rego                 # Rego policy files for each CCR
├── tests/
│   ├── test_ccr.py                # Test a single rule against a fixture or live resources
│   ├── validate_fixtures.py       # Run all fixtures against their rules (full test suite)
│   ├── fetch_fixtures.py          # Fetch real resource JSONs from Wiz Graph API
│   └── fixtures/                  # Mock resource JSON files for controlled testing
├── docs/
│   ├── creating-rules.md          # Step-by-step guide for new CCRs
│   └── rego-reference.md          # Rego language reference for Wiz CCRs
├── RULES.md                       # Complete rules reference with fixtures
├── .env                           # Wiz credentials (gitignored)
├── .gitignore
└── .terraform.lock.hcl            # Provider version lock
```

## Current Rules

This repository manages 25 CCRs across nine categories:

- **Access Key Rotation** — 8 rules enforcing key age limits by account type (service/vendor/user/untagged), each with a hard limit and early warning
- **Tag Enforcement** — 5 rules requiring valid `type` tags on IAM users, specific role lists, and roles with external trust relationships
- **Untrusted Account Sharing** — 5 rules detecting EC2 snapshots, AMIs, RDS snapshots, S3 buckets, and IAM role trusts shared with accounts outside trusted lists
- **Root Account Usage** — 1 rule alerting on root account activity, with an exemption for new accounts
- **Data Protection** — 1 rule requiring encryption on S3 buckets tagged as confidential or highly-confidential
- **Database Configuration** — 1 rule enforcing minimum 35-day backup retention on RDS instances
- **KMS Key Management** — 2 rules warning on imported key material expiration and upcoming key rotation
- **IAM Policy Hygiene** — 1 rule detecting IAM users with AWS managed policies attached
- **API Gateway Security** — 1 rule detecting API Gateway methods without authorization, with exemption for `authentication:kochid` tagged APIs

See [RULES.md](RULES.md) for the complete rules reference, including descriptions, globals dependencies, and test fixtures for each rule.

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

This runs all 86 fixture/rule combinations and reports pass/fail. When adding a new rule, add its test cases to `validate_fixtures.py` in the `TESTS` list.

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
