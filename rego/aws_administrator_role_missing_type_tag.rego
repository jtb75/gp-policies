# All Wiz custom rules must use the "wiz" package
package wiz

# Enable Rego v1 syntax (uses "if" and "in" keywords)
import rego.v1

# Default to "pass" so the rule only fails when conditions are met.
default result = "pass"

# Helper: check if this role's name is "administrator" (case-insensitive).
is_administrator_role if {
    lower(input.RoleName) == "administrator"
}

# Skip if the role name is not "administrator".
result = "skip" if {
    not is_administrator_role
}

# Helper: get the value of the "type" tag if it exists.
type_tag_value := value if {
    some tag in input.Tags
    tag.Key == "type"
    value := tag.Value
}

# Helper: true if the role has type:support tag.
has_support_tag if {
    type_tag_value == "support"
}

# Fail if the administrator role does not have type:support tag.
result = "fail" if {
    is_administrator_role
    not has_support_tag
}

# Build a description of the tag state for the finding output.
tag_status := sprintf("type=%s (expected support)", [type_tag_value]) if {
    type_tag_value
    type_tag_value != "support"
}

tag_status := "No type tag" if {
    not type_tag_value
}

# Display the current state in Wiz findings.
currentConfiguration := sprintf("Role: %s | %s", [input.RoleName, tag_status])

# Display the expected compliant state.
expectedConfiguration := "The Administrator role must have a type tag with value: support."
