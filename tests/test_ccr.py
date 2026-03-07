"""
Test a Wiz Cloud Configuration Rule against real cloud resources.

Usage:
    # Source credentials first
    source .env

    # Test a specific rego file against a native type
    python tests/test_ccr.py rego/aws_support_role_missing_type_tag.rego role

    # Optionally limit to specific cloud accounts
    python tests/test_ccr.py rego/aws_support_role_missing_type_tag.rego role --accounts 8b510f57-85d8-5ead-8139-f92ae718c88d

    # Limit the number of resources evaluated
    python tests/test_ccr.py rego/aws_missing_type_tag.rego user --first 100

Requirements:
    pip install requests
"""

import argparse
import base64
import json
import os
import sys

import requests

HEADERS_AUTH = {"Content-Type": "application/x-www-form-urlencoded"}
HEADERS = {"Content-Type": "application/json"}

QUERY = """
    query RunOPARuleTestWithEnv(
        $rule: String!,
        $nativeTypes: [String!]!,
        $cloudAccountIds: [String!],
        $projectId: String,
        $first: Int
    ) {
      cloudConfigurationRuleTest(
        rule: $rule
        nativeTypes: $nativeTypes
        cloudAccountIds: $cloudAccountIds
        projectId: $projectId
        first: $first
      ) {
        evaluations {
          result
          entity {
            providerUniqueId
            id
            type
            name
            hasOriginalObject
            properties
          }
          evidence {
            current
            expected
            path
          }
          output
        }
        passCount
        failCount
        skipCount
      }
    }
"""


def pad_base64(data):
    """Pad base64 string to a multiple of 4 characters."""
    missing_padding = len(data) % 4
    if missing_padding != 0:
        data += "=" * (4 - missing_padding)
    return data


def get_token(client_id, client_secret):
    """Authenticate with Wiz and return (token, datacenter)."""
    auth_payload = {
        "grant_type": "client_credentials",
        "audience": "wiz-api",
        "client_id": client_id,
        "client_secret": client_secret,
    }

    response = requests.post(
        url="https://auth.app.wiz.io/oauth/token",
        headers=HEADERS_AUTH,
        data=auth_payload,
        timeout=180,
    )
    response.raise_for_status()

    response_json = response.json()
    token = response_json.get("access_token")
    if not token:
        raise ValueError(f"Could not retrieve token: {response_json.get('message')}")

    # Decode the JWT payload to get the datacenter
    payload = json.loads(base64.standard_b64decode(pad_base64(token.split(".")[1])))
    return token, payload["dc"]


def run_test(token, dc, rule_code, native_types, cloud_account_ids=None, first=1000):
    """Execute the CCR test query against the Wiz API."""
    variables = {
        "rule": rule_code,
        "nativeTypes": native_types,
        "first": first,
    }
    if cloud_account_ids:
        variables["cloudAccountIds"] = cloud_account_ids

    HEADERS["Authorization"] = f"Bearer {token}"

    response = requests.post(
        url=f"https://api.{dc}.app.wiz.io/graphql",
        json={"variables": variables, "query": QUERY},
        headers=HEADERS,
        timeout=180,
    )
    response.raise_for_status()
    return response.json()


def print_results(data):
    """Print a summary of the test results."""
    test = data.get("data", {}).get("cloudConfigurationRuleTest")
    if not test:
        errors = data.get("errors", [])
        if errors:
            print("\nAPI Errors:")
            for err in errors:
                print(f"  - {err.get('message', err)}")
        else:
            print("\nUnexpected response:")
            print(json.dumps(data, indent=2))
        return

    print(f"\nResults: {test['passCount']} pass, {test['failCount']} fail, {test['skipCount']} skip\n")

    for eval_item in test.get("evaluations", []):
        result = eval_item["result"]
        entity = eval_item.get("entity", {})
        evidence = eval_item.get("evidence", {})
        name = entity.get("name", "unknown")
        provider_id = entity.get("providerUniqueId", "")

        # Color the result for readability
        if result == "FAIL":
            result_str = f"\033[31m{result}\033[0m"
        elif result == "PASS":
            result_str = f"\033[32m{result}\033[0m"
        else:
            result_str = f"\033[33m{result}\033[0m"

        print(f"  [{result_str}] {name} ({provider_id})")

        if evidence:
            current = evidence.get("current")
            expected = evidence.get("expected")
            if current:
                print(f"         Current:  {current}")
            if expected:
                print(f"         Expected: {expected}")


def main():
    parser = argparse.ArgumentParser(description="Test a Wiz CCR against real cloud resources")
    parser.add_argument("rego_file", help="Path to the .rego file to test")
    parser.add_argument("native_type", help="Native type to evaluate (e.g., user, role, bucket)")
    parser.add_argument("--accounts", nargs="*", help="Cloud account IDs to scope the test")
    parser.add_argument("--first", type=int, default=1000, help="Max resources to evaluate (default: 1000)")
    args = parser.parse_args()

    # Read credentials from environment
    client_id = os.environ.get("WIZ_CLIENT_ID")
    client_secret = os.environ.get("WIZ_CLIENT_SECRET")
    if not client_id or not client_secret:
        print("Error: WIZ_CLIENT_ID and WIZ_CLIENT_SECRET must be set.")
        print("Run: source .env")
        sys.exit(1)

    # Read the rego file
    try:
        with open(args.rego_file, "r") as f:
            rule_code = f.read()
    except FileNotFoundError:
        print(f"Error: File not found: {args.rego_file}")
        sys.exit(1)

    print(f"Testing: {args.rego_file}")
    print(f"Native type: {args.native_type}")
    if args.accounts:
        print(f"Accounts: {', '.join(args.accounts)}")

    # Authenticate
    print("Authenticating...")
    token, dc = get_token(client_id, client_secret)

    # Run the test
    print(f"Running test against {args.first} resources...")
    result = run_test(
        token=token,
        dc=dc,
        rule_code=rule_code,
        native_types=[args.native_type],
        cloud_account_ids=args.accounts,
        first=args.first,
    )

    print_results(result)


if __name__ == "__main__":
    main()
