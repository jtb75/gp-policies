# All Wiz custom rules must use the "wiz" package
package wiz

# Enable Rego v1 syntax (uses "if" and "in" keywords)
import rego.v1

# The "result" variable controls the rule outcome.
# It must return "pass", "fail", or "skip".
# We default to "pass" so the rule only fails when our conditions are met.
default result = "pass"

# The set of recognized values for the "type" tag.
recognized_types := {"user", "service", "vendor"}

# Helper: get the value of the "type" tag if it exists.
# Iterates over the Tags array looking for Key == "type".
# If no such tag exists, type_tag_value will be undefined.
type_tag_value := value if {
    some tag in input.Tags
    tag.Key == "type"
    value := tag.Value
}

# Helper: true if the user has a "type" tag with a recognized value.
has_recognized_type if {
    type_tag_value in recognized_types
}

# Fail if the user does not have a recognized type tag.
# This catches both missing tags and unrecognized values.
result = "fail" if {
    not has_recognized_type
}

# Build a description of the tag state for the finding output.
# Shows either the unrecognized tag value or that no type tag exists.
tag_status := sprintf("type=%s (unrecognized)", [type_tag_value]) if {
    type_tag_value
    not type_tag_value in recognized_types
}

tag_status := "No type tag" if {
    not type_tag_value
}

# "currentConfiguration" is displayed in Wiz findings to show
# the actual state of the resource that was evaluated.
currentConfiguration := tag_status

# "expectedConfiguration" is displayed in Wiz findings to describe
# what the compliant state should look like.
expectedConfiguration := "All IAM users must have a type tag with a valid value: user, service, or vendor."
