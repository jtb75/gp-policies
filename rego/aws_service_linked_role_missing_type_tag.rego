# All Wiz custom rules must use the "wiz" package
package wiz

# Enable Rego v1 syntax (uses "if" and "in" keywords)
import rego.v1

# Default to "pass" so the rule only fails when conditions are met.
default result = "pass"

# Helper: check if the role's Path indicates a service role or service-linked role.
# AWS uses /service-role/ and /aws-service-role/ paths for these role types.
is_service_path_role if {
    contains(lower(input.Path), "/service-role/")
}

is_service_path_role if {
    contains(lower(input.Path), "/aws-service-role/")
}

# Skip if the role is not a service-role or service-linked-role.
result = "skip" if {
    not is_service_path_role
}

# Helper: get the value of the "type" tag if it exists.
type_tag_value := value if {
    some tag in input.Tags
    tag.Key == "type"
    value := tag.Value
}

# Helper: true if the role has type:service tag.
has_service_tag if {
    type_tag_value == "service"
}

# Fail if the service/service-linked role does not have type:service tag.
result = "fail" if {
    is_service_path_role
    not has_service_tag
}

# Build a description of the tag state for the finding output.
tag_status := sprintf("type=%s (expected service)", [type_tag_value]) if {
    type_tag_value
    type_tag_value != "service"
}

tag_status := "No type tag" if {
    not type_tag_value
}

# Display the current state in Wiz findings.
currentConfiguration := sprintf("Role: %s | Path: %s | %s", [input.RoleName, input.Path, tag_status])

# Display the expected compliant state.
expectedConfiguration := "Roles with path /service-role/ or /aws-service-role/ must have a type tag with value: service."
