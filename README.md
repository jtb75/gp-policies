# GP Policies - Wiz Cloud Security Management

This repository manages Wiz Cloud Configuration Rules (CCRs), remediation actions, and supporting test infrastructure. All Wiz resources are prefixed with `JTB75` for identification within the Wiz portal.

## Repository Structure

```
gp-policies/
├── ccr/                          # Wiz CCR rules (Wiz Terraform provider)
│   ├── provider.tf               # Wiz Terraform provider configuration
│   ├── rego_packages.tf          # Custom Rego package definitions
│   ├── aws_*.tf                  # Terraform resource definitions for each CCR
│   ├── rego/
│   │   ├── packages/
│   │   │   └── jtb75_globals.rego  # Shared variables (account lists, thresholds, role names)
│   │   └── aws_*.rego            # Rego policy files for each CCR
│   └── tests/
│       ├── test_ccr.py           # Test a single rule against a fixture or live resources
│       ├── validate_fixtures.py  # Run all fixtures against their rules (full test suite)
│       ├── fetch_fixtures.py     # Fetch real resource JSONs from Wiz Graph API
│       └── fixtures/             # Mock resource JSON files for controlled testing
├── remediation-infra/            # EKS cluster for Wiz Outpost Lite (AWS Terraform provider)
│   ├── vpc.tf                    # Dedicated VPC with public/private subnets
│   ├── eks.tf                    # EKS cluster, node group, Pod Identity Agent
│   ├── iam_remediation.tf        # Runner and worker IAM roles
│   └── kubernetes.tf             # Namespace and service account
├── test-infra/                   # Disposable AWS resources to trigger CCRs (AWS Terraform provider)
│   ├── iam_roles.tf              # Roles with missing tags, untrusted trusts
│   ├── iam_users.tf              # Users with managed policies, access keys
│   ├── s3.tf                     # Buckets with untrusted sharing, missing encryption
│   ├── snapshots.tf              # EC2 snapshots shared with untrusted accounts
│   ├── rds.tf                    # RDS instances with low backup retention
│   └── api_gateway.tf            # API Gateway methods without authorization
├── docs/
│   ├── creating-rules.md         # Step-by-step guide for new CCRs
│   └── rego-reference.md         # Rego language reference for Wiz CCRs
├── RULES.md                      # Complete rules reference with fixtures
├── .env                          # Credentials (gitignored)
└── .gitignore
```

Each top-level directory (`ccr/`, `remediation-infra/`, `test-infra/`) is an independent Terraform root with its own provider, state, and `terraform apply`.

## Current Rules

This repository manages 32 CCRs across nine categories:

- **Access Key Rotation** — 8 rules enforcing key age limits by account type (service/vendor/user/untagged), each with a hard limit and early warning
- **Tag Enforcement** — 10 rules requiring valid `type` tags on IAM users, specific role lists, consumer roles, deploy roles, support-saml roles, the Administrator role, service/service-linked roles, and roles with external trust relationships
- **Untrusted Account Sharing** — 5 rules detecting EC2 snapshots, AMIs, RDS snapshots, S3 buckets, and IAM role trusts shared with accounts outside trusted lists
- **Root Account Usage** — 3 rules alerting on root account activity, programmatic access keys, and missing MFA
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
- AWS credentials (for test-infra and remediation-infra)

### Authentication

Create a `.env` file (already gitignored):

```bash
# Wiz credentials (for ccr/)
export WIZ_CLIENT_ID=your-client-id
export WIZ_CLIENT_SECRET=your-client-secret

# AWS credentials (for test-infra/ and remediation-infra/)
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-east-1
```

### Deploy CCR Rules

```bash
source .env
cd ccr
terraform init
terraform plan
terraform apply
```

### Deploy Test Infrastructure

```bash
source .env
cd test-infra
terraform init
terraform plan
terraform apply    # Creates non-compliant resources to trigger CCRs
terraform destroy  # Clean up when done testing
```

### Deploy Remediation Infrastructure

```bash
source .env
cd remediation-infra
terraform init
terraform plan
terraform apply    # Creates EKS cluster, IAM roles, namespace
```

## Testing Rules

All test commands should be run from the `ccr/` directory:

```bash
source .env
cd ccr

# Test a rule against a specific fixture
python tests/test_ccr.py rego/aws_support_role_missing_type_tag.rego role \
  --input tests/fixtures/role_support_no_type_tag.json

# Run the full test suite (111 fixture/rule combinations)
python tests/validate_fixtures.py

# Fetch real resource JSONs for fixtures
python tests/fetch_fixtures.py role --count 3

# Test against live resources
python tests/test_ccr.py rego/aws_missing_type_tag.rego user --first 500
```

**Note:** After deploying changes to the globals package via Terraform, allow up to 30 minutes for Wiz to propagate the updates before testing against live resources. The JSON test mode (`--input`) is not affected by this delay.

## Adding a New Rule

See [docs/creating-rules.md](docs/creating-rules.md) for a step-by-step guide on creating new CCRs.
