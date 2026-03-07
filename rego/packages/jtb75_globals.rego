# Custom Rego packages must use the "customPackage.<name>" namespace.
# This package is imported by rules using:
#   import data.customPackage.jtb75Globals as globals
package customPackage.jtb75Globals

# AWS accounts that belong to our organization.
# These are accounts managed internally and connected to Wiz.
trusted_internal_accounts := {
    "123456789012",
    "234567890123",
}

# AWS accounts owned by trusted third parties.
# These are external accounts we have explicitly approved for
# cross-account access (e.g., vendor or partner accounts).
trusted_external_accounts := {
    "345678901234",
}

# Combined set of all trusted accounts (internal + external).
# The "|" operator performs a set union, merging both sets into one.
# Individual rules can reference either the specific lists above
# or this combined set depending on their needs.
trusted_accounts := trusted_internal_accounts | trusted_external_accounts

# Access key rotation thresholds in days.
# Service accounts have a longer rotation window than human users.
service_key_max_age_days := 90
service_key_warning_days := 85
user_key_max_age_days := 30
user_key_warning_days := 25
vendor_key_max_age_days := 60
vendor_key_warning_days := 55

# Known support role names.
# Used to identify roles that should have a valid "type" tag.
# Role names are matched case-sensitively against this set.
kbs_support_roles := {
    "KBSSupportRole",
    "KBSSupportAdmin",
    "KBSSupportReadOnly",
    "Webserver-Role",
}
