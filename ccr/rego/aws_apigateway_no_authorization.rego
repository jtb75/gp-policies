# All Wiz custom rules must use the "wiz" package
package wiz

# Enable Rego v1 syntax (uses "if" and "in" keywords)
import rego.v1

# The "result" variable controls the rule outcome.
# It must return "pass", "fail", or "skip".
# We default to "pass" so the rule only fails when our conditions are met.
default result = "pass"

# Skip if the API Gateway has an "authentication" tag with value "kochid".
# This indicates authentication is handled externally (e.g., via KochID).
result = "skip" if {
    has_auth_exemption
}

# Helper: check if the authentication:kochid exemption tag exists.
# API Gateway tags are a simple key-value map (e.g., {"authentication": "kochid"}).
has_auth_exemption if {
    some key, val in input.Tags
    lower(key) == "authentication"
    lower(val) == "kochid"
}

# Fail if any method on any resource has AuthorizationType "NONE",
# meaning the method is open to unauthenticated requests.
result = "fail" if {
    not has_auth_exemption
    some resource in input.Resources
    some _, method in resource.ResourceMethods
    method.AuthorizationType == "NONE"
}

# Collect all unauthenticated methods for evidence.
unauth_methods := {sprintf("%s %s", [method.HttpMethod, resource.Path]) |
    some resource in input.Resources
    some _, method in resource.ResourceMethods
    method.AuthorizationType == "NONE"
}

# "currentConfiguration" is displayed in Wiz findings.
currentConfiguration := concat(", ", [sprintf("No authorization on: %s", [m]) | some m in unauth_methods])

# "expectedConfiguration" describes the compliant state.
expectedConfiguration := "All API Gateway methods should require authorization, or the API should have an authentication:kochid tag if auth is handled externally."
