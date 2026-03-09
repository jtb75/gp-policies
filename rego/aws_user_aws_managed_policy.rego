# All Wiz custom rules must use the "wiz" package
package wiz

# Enable Rego v1 syntax (uses "if" and "in" keywords)
import rego.v1

# Default to "pass" so the rule only fails when conditions are met.
default result = "pass"

# Fail if any attached managed policy is an AWS-managed policy.
# AWS-managed policy ARNs contain ":aws:policy/" (account portion is "aws").
result = "fail" if {
    some policy in input.AttachedManagedPolicies
    contains(policy.PolicyArn, ":aws:policy/")
}

# Collect all AWS-managed policy names for evidence.
aws_managed_policies := {policy.PolicyName |
    some policy in input.AttachedManagedPolicies
    contains(policy.PolicyArn, ":aws:policy/")
}

# Display the current state in Wiz findings.
currentConfiguration := sprintf("AWS managed policies attached: %s", [concat(", ", aws_managed_policies)])

# Display the expected compliant state.
expectedConfiguration := "IAM users should use customer-managed policies scoped to the specific actions and resources they need."
