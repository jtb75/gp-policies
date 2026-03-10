# All Wiz custom rules must use the "wiz" package
package wiz

# Enable Rego v1 syntax (uses "if" and "in" keywords)
import rego.v1

# Default to "pass" so the rule only fails when conditions are met.
default result = "pass"

# Valid classification values that require encryption.
classified_values := {"confidential", "highly-confidential", "highly confidential"}

# Helper: get the data-classification tag value (lowercased).
# bucketTags is an array of {"Key": ..., "Value": ...} objects.
classification_value := value if {
    some tag in input.bucketTags
    lower(tag.Key) == "data-classification"
    value := lower(tag.Value)
}

# Helper: true if the bucket has a classified data-classification tag.
is_classified if {
    classification_value in classified_values
}

# Skip buckets that don't have a classified data-classification tag.
result = "skip" if {
    not is_classified
}

# Helper: true if server-side encryption is configured on the bucket.
has_encryption if {
    some rule in input.bucketEncryptionConfiguration.ServerSideEncryptionConfiguration.Rules
    rule.ApplyServerSideEncryptionByDefault.SSEAlgorithm
}

# Fail if the bucket is classified but has no encryption.
result = "fail" if {
    is_classified
    not has_encryption
}

# Display the current state in Wiz findings.
currentConfiguration := sprintf("data-classification: %s | Encryption: %s", [
    classification_value,
    object.get(object.get(input, "bucketEncryptionConfiguration", {}), "ServerSideEncryptionConfiguration", "not configured"),
])

# Display the expected compliant state.
expectedConfiguration := "S3 buckets tagged as confidential or highly-confidential must have server-side encryption enabled."
