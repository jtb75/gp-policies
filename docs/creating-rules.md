# Creating New Cloud Configuration Rules

This guide walks through creating a new Wiz Cloud Configuration Rule (CCR) in this repository.

## Overview

Each CCR consists of two files:

1. **A Terraform file** (`.tf`) in the repo root - defines the rule metadata (name, severity, target type, remediation)
2. **A Rego file** (`.rego`) in `rego/` - contains the policy logic that evaluates the resource

## Step 1: Get the Resource JSON from Wiz

Before writing any Rego, you need to understand the data structure of the resource you're evaluating.

1. In the Wiz portal, go to **Policies > Cloud Configuration Rules**
2. Click **Create Custom Rule**
3. Select the **Native Type** you want to target (e.g., `user`, `bucket`, `role`)
4. In the **Test Data** pane, toggle to **Environment** mode
5. Browse or shuffle through real resources to see their JSON structure
6. Note the `nativeType` value in `WizMetadata` - you'll need the exact string for `target_native_types`

## Step 2: Create the Terraform Resource

Create a new `.tf` file in the repo root. Follow the naming convention: `aws_<descriptive_name>.tf`

```hcl
resource "wiz_cloud_configuration_rule" "descriptive_resource_name" {
  name                     = "JTB75 - Human-readable rule name"
  description              = "What this rule checks for."
  target_native_types      = ["nativeType"]   # From WizMetadata
  severity                 = "HIGH"            # INFORMATIONAL, LOW, MEDIUM, HIGH, CRITICAL
  enabled                  = true
  remediation_instructions = <<-EOT
    Step-by-step remediation instructions.
    Supports **Markdown** formatting.
  EOT

  opa_policy = file("${path.module}/rego/<matching_rego_filename>.rego")
}
```

### Key Fields

| Field | Description |
|-------|-------------|
| `name` | Always prefix with `JTB75 -`. Displayed in the Wiz portal. |
| `target_native_types` | The Wiz native type(s) to evaluate. Must match `WizMetadata.nativeType` exactly. |
| `severity` | `INFORMATIONAL`, `LOW`, `MEDIUM`, `HIGH`, or `CRITICAL` |
| `opa_policy` | Path to the Rego file. Uses `file()` function with `${path.module}` as the base. |
| `remediation_instructions` | Markdown-formatted steps shown to the user when a finding is generated. |

## Step 3: Write the Rego Policy

Create a matching `.rego` file in `rego/`. The file must follow this structure:

```rego
# All Wiz custom rules must use the "wiz" package
package wiz

# Enable Rego v1 syntax
import rego.v1

# Default to "pass" - the rule only fails when conditions are met
default result = "pass"

# Your evaluation logic here
result = "fail" if {
    # conditions that indicate non-compliance
}

# What the resource currently looks like (shown in Wiz findings)
currentConfiguration := "Description of the current state"

# What compliance looks like (shown in Wiz findings)
expectedConfiguration := "Description of the expected state"
```

### Required Elements

| Element | Description |
|---------|-------------|
| `package wiz` | Must always be the first declaration |
| `default result = "pass"` | Ensures the rule passes unless explicitly failed |
| `result = "fail"` | One or more rules that set the result to "fail" when conditions are met |
| `currentConfiguration` | String shown in findings describing the actual state |
| `expectedConfiguration` | String shown in findings describing the expected state |

### Optional Elements

| Element | Description |
|---------|-------------|
| `result = "skip"` | Return "skip" to exclude a resource from evaluation entirely |
| `import data.customPackage.jtb75Globals as globals` | Import shared variables from the globals package |

## Step 4: Test Your Rule

There are two ways to test before deploying. The test script (`tests/test_ccr.py`) is recommended since it provides a repeatable workflow.

### Option A: Test with Mock JSON (Recommended)

Create a JSON fixture in `tests/fixtures/` by copying a resource's JSON from the Wiz CCR editor's Test Data pane, then run:

```bash
source .env
python tests/test_ccr.py rego/your_rule.rego <native_type> --input tests/fixtures/your_fixture.json
```

Create fixtures for each expected outcome (pass, fail, skip) to validate all code paths. This approach uses the `cloudConfigurationRuleJsonTest` API, which evaluates instantly — it does not require globals propagation.

You can also fetch real resource JSONs to use as fixture starting points:

```bash
python tests/fetch_fixtures.py <native_type> --count 3
```

### Option B: Test in the Wiz Portal

1. Go to **Policies > Cloud Configuration Rules > Create Custom Rule**
2. Select your target native type
3. Paste your Rego code in the Rule pane
4. Use the Test Data pane to load real resources or paste custom JSON
5. Click **Run Test** to verify pass/fail/skip behavior

### Option C: Test Against Live Resources

```bash
source .env
python tests/test_ccr.py rego/your_rule.rego <native_type> --first 500
```

**Important:** If your rule references the globals package and you recently changed it, allow up to 30 minutes for Wiz to propagate the updates before testing against live resources. Use Option A for instant feedback.

## Step 5: Add Test Fixtures

Create pass/fail/skip fixture files in `tests/fixtures/` and register them in `tests/validate_fixtures.py`:

```python
# In the TESTS list, add entries for your new rule:
("your_fixture_pass.json", "rego/your_rule.rego", "native_type", "pass"),
("your_fixture_fail.json", "rego/your_rule.rego", "native_type", "fail"),
("your_fixture_skip.json", "rego/your_rule.rego", "native_type", "skip"),
```

Then verify all tests still pass:

```bash
source .env
python tests/validate_fixtures.py
```

## Step 6: Deploy

```bash
source .env
terraform plan    # Review changes
terraform apply   # Deploy to Wiz
```

## Using the Globals Package

To reference shared variables, import the globals package:

```rego
import data.customPackage.jtb75Globals as globals
```

Then use variables like:

```rego
# Check against trusted accounts
not account_id in globals.trusted_internal_accounts

# Use rotation thresholds
threshold_ns := globals.service_key_max_age_days * 24 * 60 * 60 * 1000000000

# Check against known role names
input.RoleName in globals.kbs_support_roles
```

To add new shared variables, edit `rego/packages/jtb75_globals.rego`. Changes are deployed via the `wiz_custom_rego_package` resource in `rego_packages.tf`.

**Propagation delay:** After deploying changes to the globals package, Wiz can take up to 30 minutes to propagate the updates. During this window, rules tested against live resources (via the Wiz portal or `cloudConfigurationRuleTest` API) may not see the latest globals values. To test immediately, use the JSON test mode (`--input` flag) which always resolves globals correctly regardless of propagation state.

## Common Patterns

### Tag Checking — Array Format (IAM Roles, Users, S3 Buckets)

IAM roles, users, and S3 buckets use an array-of-objects format for tags:

```rego
# IAM roles/users: input.Tags is [{Key, Value}, ...]
has_type_tag if {
    some tag in input.Tags
    lower(tag.Key) == "type"
    lower(tag.Value) == "service"
}

# S3 buckets use a different field name but same format:
# input.bucketTags is [{Key, Value}, ...]
has_confidential_tag if {
    some tag in input.bucketTags
    lower(tag.Key) == "classification"
    lower(tag.Value) == "confidential"
}
```

### Tag Checking — Map Format (API Gateway)

API Gateway resources use a simple key-value map for tags:

```rego
# API Gateway: input.Tags is {"key": "value", ...}
has_auth_exemption if {
    some key, val in input.Tags
    lower(key) == "authentication"
    lower(val) == "kochid"
}
```

**Important:** Always check the actual resource JSON from Wiz to determine which tag format a native type uses. Using the wrong iteration pattern will silently produce no matches.

### Name-Based Matching

Match resources by name pattern (case-insensitive):

```rego
# Contains check — matches "consumer-role", "MyConsumerAccess", etc.
is_consumer_role if {
    contains(lower(input.RoleName), "consumer")
}

# Exact match
is_administrator if {
    lower(input.RoleName) == "administrator"
}

# Prefix check
is_deploy_role if {
    contains(lower(input.RoleName), "deploy-")
}
```

### Path-Based Matching

Match IAM roles by their AWS path:

```rego
# Service roles use /service-role/ or /aws-service-role/ paths
is_service_path_role if {
    contains(lower(input.Path), "/service-role/")
}

is_service_path_role if {
    contains(lower(input.Path), "/aws-service-role/")
}
```

Note: Multiple definitions of the same helper rule act as OR — the role matches if it has either path.

### Skip/Fail Guard Pattern

When a rule has both `skip` and `fail` results, Rego can conflict if both conditions are true simultaneously. Use a guard to prevent this:

```rego
# Helper to check skip condition
is_skip if {
    not is_consumer_role
}

# Skip non-matching resources
result = "skip" if {
    is_skip
}

# Only fail if we didn't skip — the "not is_skip" guard prevents conflicts
result = "fail" if {
    not is_skip
    not has_correct_tag
}
```

**Why this matters:** Without the `not is_skip` guard in the fail rule, Rego may try to assign both `"skip"` and `"fail"` to `result` simultaneously, which causes a conflict error. The guard ensures only one result can be assigned.

### Parsing JSON String Fields

Some AWS fields (like `AssumeRolePolicyDocument`, `bucketPolicy`) are JSON strings, not objects. You must parse them before traversal:

```rego
# Parse the trust policy (it's a JSON string, not an object)
trust_policy := json.unmarshal(input.AssumeRolePolicyDocument)

# Now traverse normally
result = "fail" if {
    some statement in trust_policy.Statement
    statement.Effect == "Allow"
    statement.Principal == "*"
}
```

**Tip:** If a field looks like it should be an object but your rule isn't matching, check whether it's actually a JSON string that needs `json.unmarshal()`.

### Handling String-or-Array Fields

Some AWS fields can be either a single string or an array (e.g., `Principal.AWS` in trust policies). Handle both:

```rego
# When Principal.AWS is an array
cross_account_ids := {account_id |
    some statement in trust_policy.Statement
    statement.Effect == "Allow"
    principal := statement.Principal.AWS[_]
    parts := split(principal, ":")
    account_id := parts[4]
}

# When Principal.AWS is a single string
cross_account_ids_single := {account_id |
    some statement in trust_policy.Statement
    statement.Effect == "Allow"
    principal := statement.Principal.AWS
    is_string(principal)
    parts := split(principal, ":")
    account_id := parts[4]
}

# Union both sets
all_cross_account_ids := cross_account_ids | cross_account_ids_single
```

### Compare Timestamps

```rego
# Define threshold in nanoseconds (Rego uses nanoseconds for time)
ninety_days_ns := 90 * 24 * 60 * 60 * 1000000000

# Get current time
now := time.now_ns()

# Parse an RFC3339 timestamp and compare
is_expired if {
    created := time.parse_rfc3339_ns(input.CreateDate)
    now - created > ninety_days_ns
}
```

### Extract Account ID from ARN

```rego
# ARN format: arn:aws:iam::<account_id>:<resource>
extract_account(arn) := account_id if {
    parts := split(arn, ":")
    count(parts) >= 5
    account_id := parts[4]
    account_id != ""
}
```

### Set Comprehensions

Build a set of values matching a condition:

```rego
# Collect all account IDs that are untrusted
untrusted := {id |
    some item in input.Permissions
    id := item.AccountId
    not id in globals.trusted_accounts
}
```

## Testing Best Practices

### Fixture Naming Convention

Fixtures follow the pattern: `<nativeType>_<rule_description>_<outcome>.json`

Examples:
- `role_consumer_no_type_tag.json` → fail (consumer role, missing tag)
- `role_consumer_valid_type_tag.json` → pass (consumer role, correct tag)
- `role_not_consumer.json` → skip (not a consumer role)
- `rootuser_mfa_fail.json` → fail (root missing MFA)

### Create Pass, Fail, and Skip Fixtures

Every rule should have at minimum:
- **fail** fixture: triggers the violation
- **pass** fixture: satisfies the requirement
- **skip** fixture (if applicable): resource that should be excluded from evaluation

For tag enforcement rules, also consider a **bad tag** fixture (has the tag key but wrong value).

### Sanitize Fixtures

Always replace real AWS account IDs with `123456789012` in fixture files. When fetching real resources with `fetch_fixtures.py`, sanitize before committing.

### Future-Proof Time-Based Fixtures

For rules that check timestamps against `time.now_ns()`, use far-future dates (e.g., `2099-01-01T00:00:00Z`) in fixtures that should always pass the time check, and far-past dates for fixtures that should always fail. This prevents fixtures from breaking as time passes.

### Globals Propagation Delay

After deploying changes to the globals package via `terraform apply`, Wiz can take **10-30+ minutes** to propagate updates. During this window:

- **JSON test mode** (`--input` flag / `cloudConfigurationRuleJsonTest` API) works immediately — use this for development
- **Live resource tests** and the Wiz portal may use stale globals values
- **New global variables** that haven't propagated yet will be `undefined`, which can cause rules to silently produce unexpected results (typically defaulting to "pass")
