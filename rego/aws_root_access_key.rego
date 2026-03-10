# All Wiz custom rules must use the "wiz" package
package wiz

# Enable Rego v1 syntax (uses "if" and "in" keywords)
import rego.v1

# Default to "pass" so the rule only fails when conditions are met.
default result = "pass"

# Fail if the root account has an active access key.
# AccessKey1Active and AccessKey2Active are strings ("true"/"false").
result = "fail" if {
    input.userCredentials.AccessKey1Active == "true"
}

result = "fail" if {
    input.userCredentials.AccessKey2Active == "true"
}

# Build evidence showing which keys are active.
active_keys := [key |
    some k in ["AccessKey1Active", "AccessKey2Active"]
    input.userCredentials[k] == "true"
    key := k
]

# Display the current state in Wiz findings.
currentConfiguration := sprintf("Root account has active access keys: %s", [concat(", ", active_keys)])

# Display the expected compliant state.
expectedConfiguration := "Root accounts should not have programmatic access keys. Use IAM roles or IAM users instead."
