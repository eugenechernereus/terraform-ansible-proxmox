#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export ANSIBLE_PRIVATE_KEY_FILE="${ANSIBLE_PRIVATE_KEY_FILE:-$HOME/.ssh/id_ed25519}"

cd "$ROOT"

echo "==> Checking SSH private key"

if [[ ! -f "$ANSIBLE_PRIVATE_KEY_FILE" ]]; then
    echo "ERROR: SSH private key not found: $ANSIBLE_PRIVATE_KEY_FILE" >&2
    exit 1
fi

echo "==> Generating Ansible inventory"
python3 scripts/generate_inventory.py

echo "==> Generating SSH known_hosts"
python3 scripts/generate_known_hosts.py --timeout 300

echo "==> SSH preparation completed"

