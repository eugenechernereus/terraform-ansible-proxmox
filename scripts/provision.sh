#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

if [[ -z "${TF_VAR_proxmox_api_token:-}" ]]; then
    TOKEN_FILE="$HOME/.config/proxmox-lab/api-token"

    if [[ ! -f "$TOKEN_FILE" ]]; then
        echo "ERROR: Proxmox API token is not configured" >&2
        exit 1
    fi

    export TF_VAR_proxmox_api_token="$(< "$TOKEN_FILE")"
fi

echo "==> Initializing Terraform"
terraform init

echo "==> Formatting Terraform files"
terraform fmt -recursive

echo "==> Validating Terraform configuration"
terraform validate

echo "==> Creating Terraform plan"
terraform plan -out=tfplan

echo "==> Applying Terraform plan"
terraform apply -auto-approve tfplan

rm -f tfplan

echo "==> Infrastructure provisioning completed"

