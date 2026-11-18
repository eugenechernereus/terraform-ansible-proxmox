#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "======================================"
echo "       PROXMOX INFRASTRUCTURE"
echo "======================================"

echo
echo "STEP 1/3: Provision infrastructure"
"$ROOT/scripts/provision.sh"

echo
echo "STEP 2/3: Prepare SSH and inventory"
"$ROOT/scripts/prepare_ssh.sh"

echo
echo "STEP 3/3: Configure virtual machines"
"$ROOT/scripts/configure.sh"

echo
echo "======================================"
echo "       DEPLOYMENT COMPLETED"
echo "======================================"

