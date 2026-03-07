# Rego Language Reference for Wiz CCRs

This document covers the Rego language fundamentals needed to write and maintain Wiz Cloud Configuration Rules.

## What is Rego?

Rego is the policy language used by Open Policy Agent (OPA). Wiz uses OPA v1.4.2 with Rego V0 syntax, though V1 keywords are supported via `import rego.v1`. All policies in this repo use V1 syntax.

Rego is declarative - you describe what conditions constitute a policy violation, not how to check for them. The engine evaluates all rules and determines the result.

## How Wiz Evaluates Rego

When Wiz runs a CCR against a resource:

1. The resource's JSON data is provided as `input`
2. Your Rego policy evaluates against that `input`
3. The `result` variable determines the outcome: `"pass"`, `"fail"`, or `"skip"`
4. If the result is `"fail"`, Wiz generates a finding with `currentConfiguration` and `expectedConfiguration`

### The Input Object

The `input` variable contains the full JSON representation of the resource being evaluated. The structure varies by native type. Always get a sample JSON from the Wiz CCR editor before writing a rule.

Example for an IAM user:

```json
{
  "UserName": "example-user",
  "Tags": [
    { "Key": "type", "Value": "service" }
  ],
  "userCredentials": {
    "AccessKey1Active": "true",
    "AccessKey1LastRotated": "2024-01-15T10:30:00Z"
  },
  "WizMetadata": {
    "nativeType": "user"
  }
}
```

Access fields with dot notation: `input.UserName`, `input.Tags`, `input.userCredentials.AccessKey1Active`.

## Variables and Assignments

### `:=` (Local Assignment)

Assigns a value within a scope. Cannot be reassigned.

```rego
threshold := 90
name := input.UserName
```

### `=` (Unification)

Used for rule heads. Can have multiple definitions (which act as OR).

```rego
result = "fail" if { ... }
result = "fail" if { ... }   # Another way to fail (OR)
```

### `default`

Sets a fallback value when no rule matches.

```rego
default result = "pass"   # Pass unless a "fail" rule matches
```

## Data Types

| Type | Example | Notes |
|------|---------|-------|
| String | `"hello"` | Double quotes only |
| Number | `42`, `3.14` | Integer or float |
| Boolean | `true`, `false` | Lowercase |
| Null | `null` | |
| Array | `["a", "b", "c"]` | Ordered, indexed by position |
| Object | `{"key": "value"}` | Key-value pairs |
| Set | `{"a", "b", "c"}` | Unordered, unique values, uses `{}` like objects but without keys |

## Rules

Rules are the core building blocks. A rule defines when a variable takes a specific value.

### Basic Rule

```rego
# result becomes "fail" when all conditions in the body are true
result = "fail" if {
    input.Encrypted == false
}
```

### Multiple Conditions (AND)

All conditions within a rule body must be true (implicit AND):

```rego
result = "fail" if {
    input.IsPublic == true         # AND
    input.Encrypted == false       # AND
    input.Region == "us-east-1"    # all three must be true
}
```

### Multiple Rules (OR)

Multiple rules with the same head act as OR:

```rego
result = "fail" if {
    input.IsPublic == true     # fails if public
}

result = "fail" if {
    input.Encrypted == false   # OR fails if unencrypted
}
```

### Helper Rules

Break complex logic into named helpers for readability:

```rego
is_public if {
    input.IsPublic == true
}

is_unencrypted if {
    input.Encrypted == false
}

result = "fail" if {
    is_public
    is_unencrypted
}
```

## Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `==` | Equal | `input.Status == "active"` |
| `!=` | Not equal | `input.Status != "active"` |
| `<` | Less than | `input.Count < 10` |
| `<=` | Less than or equal | `input.Count <= 10` |
| `>` | Greater than | `input.Count > 10` |
| `>=` | Greater than or equal | `input.Count >= 10` |
| `not` | Negation | `not input.Encrypted` |
| `in` | Membership (V1) | `"admin" in input.Roles` |

### Negation

`not` negates a condition or rule:

```rego
result = "fail" if {
    not input.Encrypted        # true when Encrypted is false/undefined
}

result = "fail" if {
    not is_trusted(account_id)  # true when the helper rule doesn't match
}
```

## Iteration

### Over Arrays

```rego
# Iterate with index variable
result = "fail" if {
    some i
    input.Ports[i] == 22
}

# Iterate with value (Rego V1)
result = "fail" if {
    some port in input.Ports
    port == 22
}

# Wildcard (don't need the index)
result = "fail" if {
    input.Ports[_] == 22
}
```

### Over Objects

```rego
# Iterate over key-value pairs
result = "fail" if {
    some key, value in input.Tags
    key == "environment"
    value == "production"
}
```

### Over Arrays of Objects

```rego
# Common pattern: find a specific item in an array of objects
result = "fail" if {
    some tag in input.Tags
    tag.Key == "type"
    tag.Value == "admin"
}
```

## Functions

### User-Defined Functions

```rego
# Function with a parameter that returns a value
extract_account(arn) := account_id if {
    parts := split(arn, ":")
    count(parts) >= 5
    account_id := parts[4]
}

# Function that acts as a boolean check (no return value)
is_trusted(account_id) if {
    account_id in globals.trusted_accounts
}
```

### Key Built-in Functions

#### String Functions

```rego
contains("hello world", "world")           # true
startswith("hello", "hel")                  # true
endswith("hello.txt", ".txt")              # true
lower("HELLO")                             # "hello"
upper("hello")                             # "HELLO"
split("a:b:c", ":")                        # ["a", "b", "c"]
concat(", ", ["a", "b", "c"])              # "a, b, c"
sprintf("Hello %s, count: %d", ["world", 5]) # "Hello world, count: 5"
trim_space("  hello  ")                    # "hello"
```

#### Collection Functions

```rego
count([1, 2, 3])                           # 3
count({"a", "b"})                          # 2
array.concat([1, 2], [3, 4])              # [1, 2, 3, 4]
object.get(obj, "key", "default")          # get with default value
```

#### Set Operations

```rego
set_a | set_b                              # union
set_a & set_b                              # intersection
set_a - set_b                              # difference
```

#### Type Checking

```rego
is_string("hello")                         # true
is_array([1, 2])                           # true
is_object({"a": 1})                        # true
is_number(42)                              # true
is_boolean(true)                           # true
is_null(null)                              # true
```

#### Time Functions

Rego time functions work in **nanoseconds**.

```rego
# Current time in nanoseconds
now := time.now_ns()

# Parse RFC3339 timestamp to nanoseconds
ts := time.parse_rfc3339_ns("2024-01-15T10:30:00Z")

# Parse duration string to nanoseconds
dur := time.parse_duration_ns("24h")

# Common pattern: days to nanoseconds
ninety_days := 90 * 24 * 60 * 60 * 1000000000
```

#### JSON Functions

```rego
# Parse a JSON string into an object
obj := json.unmarshal("{\"key\": \"value\"}")

# Convert an object to a JSON string
str := json.marshal({"key": "value"})
```

#### Network Functions

```rego
net.cidr_contains("10.0.0.0/8", "10.1.2.3")       # true
net.cidr_intersects("10.0.0.0/8", "10.1.0.0/16")   # true
```

## Comprehensions

Build collections from iteration with filtering.

### Set Comprehension

```rego
# Collect unique account IDs that are untrusted
untrusted := {id |
    some perm in input.Permissions
    id := perm.AccountId
    not id in globals.trusted_accounts
}
```

### Array Comprehension

```rego
# Build an array of formatted messages
messages := [msg |
    some acct in untrusted_accounts
    msg := sprintf("Untrusted: %s", [acct])
]
```

## Undefined vs False

This is a critical Rego concept. A value can be:

- **Defined and true**: The rule matched
- **Defined and false**: The rule explicitly returned false
- **Undefined**: The rule couldn't be evaluated (e.g., the field doesn't exist)

`not` treats both false and undefined the same way:

```rego
# This is true when:
# - input.Encrypted is false
# - input.Encrypted doesn't exist in the input at all
not input.Encrypted
```

This matters when checking optional fields. If a field might not exist, `not` handles it safely. But direct comparisons on missing fields will cause the rule to be undefined (not fail):

```rego
# SAFE: works even if Encrypted is missing
not input.Encrypted

# RISKY: if Encrypted is missing, this whole rule becomes undefined
input.Encrypted == false
```

## Wiz-Specific Conventions

### Custom Rego Packages

Shared code lives in packages under `customPackage.<name>`:

```rego
# In the package file:
package customPackage.jtb75Globals
my_variable := "value"

# In a rule file, import and use it:
import data.customPackage.jtb75Globals as globals
globals.my_variable   # "value"
```

After creating or modifying a custom package, allow approximately 10 minutes for Wiz to recognize the changes before rules can reference new variables.

### Result Values

| Value | Meaning |
|-------|---------|
| `"pass"` | Resource is compliant |
| `"fail"` | Resource is non-compliant; Wiz generates a finding |
| `"skip"` | Resource is excluded from evaluation (not counted as pass or fail) |

### Finding Output

```rego
# What the resource currently looks like
currentConfiguration := "The actual state found during evaluation"

# What compliance looks like
expectedConfiguration := "The desired compliant state"
```

These strings appear in the Wiz finding and support dynamic values via `sprintf()`.

## Debugging Tips

1. **Use the Wiz CCR editor** to test policies against real resource data before deploying
2. **Start simple** - get a basic pass/fail working, then add complexity
3. **Check field names carefully** - they are case-sensitive and must match the JSON exactly
4. **Use `sprintf` in `currentConfiguration`** to surface the actual values that caused a failure
5. **Test with both passing and failing data** to verify both code paths
6. **Use the OPA Playground** (https://play.openpolicyagent.org/) for quick Rego syntax experiments

## Further Reading

- [OPA Rego Documentation](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Rego Style Guide](https://github.com/StyraInc/rego-style-guide)
