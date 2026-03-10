# All Wiz custom rules must use the "wiz" package
package wiz

# Enable Rego v1 syntax (uses "if" and "in" keywords)
import rego.v1

# Default to "pass" so the rule only fails when conditions are met.
default result = "pass"

# The set of recognized values for the "type" tag.
# Helper: check if this role's name contains "deploy-" (case-insensitive).
is_deploy_role if {
    contains(lower(input.RoleName), "deploy-")
}

# Skip if the role name does not contain "deploy-".
result = "skip" if {
    not is_deploy_role
}

# Helper: get the value of the "type" tag if it exists.
type_tag_value := value if {
    some tag in input.Tags
    tag.Key == "type"
    value := tag.Value
}

# Helper: true if the role has type:deployment tag.
has_deployment_tag if {
    type_tag_value == "deployment"
}

# Fail if the deploy role does not have type:deployment tag.
result = "fail" if {
    is_deploy_role
    not has_deployment_tag
}

# Build a description of the tag state for the finding output.
tag_status := sprintf("type=%s (expected deployment)", [type_tag_value]) if {
    type_tag_value
    type_tag_value != "deployment"
}

tag_status := "No type tag" if {
    not type_tag_value
}

# Display the current state in Wiz findings.
currentConfiguration := sprintf("Role: %s | %s", [input.RoleName, tag_status])

# Display the expected compliant state.
expectedConfiguration := "Roles with 'deploy-' in their name must have a type tag with value: deployment."
