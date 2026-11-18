#!/usr/bin/env python3

import json
import os
import subprocess
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INVENTORY_PATH = PROJECT_ROOT / "ansible" / "inventory" / "hosts.yml"


def terraform_output(name):
    """Получаем output Terraform в формате JSON."""

    result = subprocess.run(
        ["terraform", "output", "-json", name],
        cwd=PROJECT_ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    return json.loads(result.stdout)


def main():
    try:
        vms = terraform_output("vm_ips")
        ansible_config = terraform_output("ansible_config")

        if not vms:
            raise ValueError("Terraform output contains no VMs.")

        private_key = os.environ.get("ANSIBLE_PRIVATE_KEY_FILE")

        if not private_key:
            raise ValueError(
                "Environment variable "
                "ANSIBLE_PRIVATE_KEY_FILE is not set."
            )

        private_key = str(Path(private_key).expanduser().resolve())

        if not Path(private_key).is_file():
            raise FileNotFoundError(
                f"SSH private key not found: {private_key}"
            )

        inventory = {
            "all": {
                "children": {},
                "vars": {
                    "ansible_user": ansible_config["user"],
                    "ansible_ssh_private_key_file": private_key,
                    "ansible_become": True,
                },
            }
        }

        for name, ip in vms.items():
            group = name.split("-", 1)[0]

            inventory["all"]["children"].setdefault(
                group, {"hosts": {}}
            )

            inventory["all"]["children"][group]["hosts"][name] = {
                "ansible_host": ip,
            }

        INVENTORY_PATH.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        INVENTORY_PATH.write_text(
            json.dumps(inventory, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

        print(f"Inventory generated: {INVENTORY_PATH}")
        print(f"VMs found: {len(vms)}")

    except (subprocess.CalledProcessError, ValueError,
            KeyError, FileNotFoundError, OSError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

