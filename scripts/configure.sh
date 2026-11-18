#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/ansible"

echo "==> Configuring virtual machines"

ansible-playbook playbooks/site.yml

echo "==> Running health checks"

ansible-playbook playbooks/healthcheck.yml

echo "==> Configuration completed successfully"

