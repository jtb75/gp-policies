"""
Fetch sample resource JSONs from Wiz and save them as test fixtures.

Uses a two-step approach:
  1. graphSearch to find entity IDs by native type
  2. graphEntity with providerData to get the raw cloud resource JSON

Usage:
    source .env
    python tests/fetch_fixtures.py role
    python tests/fetch_fixtures.py user --count 3
    python tests/fetch_fixtures.py bucket --count 5

Saves fixtures to tests/fixtures/<nativeType>_<name>.json
"""

import argparse
import base64
import json
import os
import re
import sys

import requests

HEADERS_AUTH = {"Content-Type": "application/x-www-form-urlencoded"}
HEADERS = {"Content-Type": "application/json"}

# Map native types to Wiz graph entity types.
# Some native types may map to multiple entity types - the script
# tries the first one that returns results.
NATIVE_TYPE_TO_ENTITY = {
    "role": ["SERVICE_ACCOUNT"],
    "user": ["SERVICE_ACCOUNT", "IDENTITY"],
    "bucket": ["BUCKET"],
    "ec2#encryptedsnapshot": ["SNAPSHOT"],
    "ec2#unencryptedsnapshot": ["SNAPSHOT"],
    "rootUser": ["USER_ACCOUNT"],
    "resourcePolicy": ["RESOURCE"],
}

# Step 1: Find entity IDs by native type
SEARCH_QUERY = """
    query GraphSearch($query: GraphEntityQueryInput, $projectId: String!, $first: Int) {
      graphSearch(
        query: $query
        projectId: $projectId
        first: $first
        quick: true
      ) {
        nodes {
          entities {
            id
            name
            type
            providerUniqueId
          }
        }
      }
    }
"""

# Step 2: Get the raw cloud resource JSON for an entity
ENTITY_QUERY = """
    query LoadGraphEntityJSON($id: ID!) {
      graphEntity(id: $id) {
        type
        providerUniqueId
        id
        providerData
      }
    }
"""


def pad_base64(data):
    missing_padding = len(data) % 4
    if missing_padding != 0:
        data += "=" * (4 - missing_padding)
    return data


def get_token(client_id, client_secret):
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
    payload = json.loads(base64.standard_b64decode(pad_base64(token.split(".")[1])))
    return token, payload["dc"]


def query_api(dc, query, variables):
    response = requests.post(
        url=f"https://api.{dc}.app.wiz.io/graphql",
        json={"variables": variables, "query": query},
        headers=HEADERS,
        timeout=180,
    )
    response.raise_for_status()
    return response.json()


def find_entities(dc, native_type, count):
    """Search for entities by native type, return list of (id, name)."""
    entity_types = NATIVE_TYPE_TO_ENTITY.get(native_type, ["RESOURCE"])

    for entity_type in entity_types:
        variables = {
            "first": count,
            "query": {
                "type": [entity_type],
                "select": True,
                "where": {
                    "nativeType": {
                        "EQUALS": [native_type],
                    },
                },
            },
            "projectId": "*",
        }

        data = query_api(dc, SEARCH_QUERY, variables)
        errors = data.get("errors", [])
        if errors:
            continue

        nodes = data.get("data", {}).get("graphSearch", {}).get("nodes", [])
        if nodes:
            entities = []
            for node in nodes:
                for entity in node.get("entities", []):
                    entities.append((entity["id"], entity.get("name", "unknown")))
            return entities

    return []


def fetch_provider_data(dc, entity_id):
    """Fetch the raw cloud resource JSON for a single entity."""
    data = query_api(dc, ENTITY_QUERY, {"id": entity_id})
    entity = data.get("data", {}).get("graphEntity")
    if not entity:
        return None
    provider_data = entity.get("providerData")
    if not provider_data:
        return None
    if isinstance(provider_data, str):
        return json.loads(provider_data)
    return provider_data


def sanitize_filename(name):
    """Convert a resource name to a safe filename."""
    name = name.lower()
    name = re.sub(r"[^a-z0-9_\-]", "_", name)
    name = re.sub(r"_+", "_", name).strip("_")
    return name[:80]


def main():
    parser = argparse.ArgumentParser(description="Fetch sample resource JSONs from Wiz")
    parser.add_argument("native_type", help="Native type to fetch (e.g., role, user, bucket)")
    parser.add_argument("--count", type=int, default=3, help="Number of resources to fetch (default: 3)")
    parser.add_argument("--output", default="tests/fixtures", help="Output directory (default: tests/fixtures)")
    args = parser.parse_args()

    client_id = os.environ.get("WIZ_CLIENT_ID")
    client_secret = os.environ.get("WIZ_CLIENT_SECRET")
    if not client_id or not client_secret:
        print("Error: WIZ_CLIENT_ID and WIZ_CLIENT_SECRET must be set.")
        sys.exit(1)

    os.makedirs(args.output, exist_ok=True)

    print("Authenticating...")
    token, dc = get_token(client_id, client_secret)
    HEADERS["Authorization"] = f"Bearer {token}"

    print(f"Searching for {args.count} '{args.native_type}' resources...")
    entities = find_entities(dc, args.native_type, args.count)

    if not entities:
        print("No resources found.")
        sys.exit(0)

    print(f"Found {len(entities)} entities. Fetching provider data...\n")

    saved = 0
    for entity_id, name in entities:
        provider_data = fetch_provider_data(dc, entity_id)
        if not provider_data:
            print(f"  Skipped: {name} (no provider data)")
            continue

        safe_name = sanitize_filename(name)
        filename = f"{args.native_type}_{safe_name}.json"
        filepath = os.path.join(args.output, filename)

        with open(filepath, "w") as f:
            json.dump(provider_data, f, indent=2)

        print(f"  Saved: {filename} ({name})")
        saved += 1

    print(f"\n{saved} fixture(s) saved to {args.output}/")


if __name__ == "__main__":
    main()
