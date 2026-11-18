#!/usr/bin/env python3

import argparse
import ipaddress
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
KNOWN_HOSTS = Path.home() / ".ssh" / "known_hosts"

KEY_TYPES = "ed25519,ecdsa,rsa"


def get_vm_ips():
    """Получаем IP виртуальных машин из Terraform outputs."""

    result = subprocess.run(
        ["terraform", "output", "-json", "vm_ips"],
        cwd=PROJECT_ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    vms = json.loads(result.stdout)

    if not vms:
        raise RuntimeError("Terraform output contains no VMs.")

    ips = []

    for name, raw_ip in vms.items():
        ip = str(ipaddress.ip_address(raw_ip))
        ips.append((name, ip))

    return ips


def scan_host(ip):
    """Получаем SSH host keys через ssh-keyscan."""

    result = subprocess.run(
        [
            "ssh-keyscan",
            "-T", "5",
            "-H",
            "-t", KEY_TYPES,
            ip,
        ],
        capture_output=True,
        text=True,
        timeout=10,
    )

    lines = [
        line
        for line in result.stdout.splitlines()
        if line.strip() and not line.startswith("#")
    ]

    return lines


def wait_for_ssh(name, ip, timeout, interval):
    """Ожидаем появления SSH host keys."""

    print(f"Waiting for SSH: {name} ({ip})")

    deadline = time.monotonic() + timeout

    while time.monotonic() < deadline:
        try:
            keys = scan_host(ip)

            if keys:
                print(f"SSH available: {name} ({ip})")
                return keys

        except (subprocess.TimeoutExpired, OSError):
            pass

        time.sleep(interval)

    raise TimeoutError(
        f"SSH timeout: {name} ({ip})"
    )


def find_existing_keys(ip):
    """Ищем уже сохранённые ключи для IP."""

    if not KNOWN_HOSTS.exists():
        return set()

    result = subprocess.run(
        [
            "ssh-keygen",
            "-F", ip,
            "-f", str(KNOWN_HOSTS),
        ],
        capture_output=True,
        text=True,
    )

    keys = set()

    for line in result.stdout.splitlines():
        if not line or line.startswith("#"):
            continue

        fields = line.split()

        if len(fields) >= 3:
            keys.add((fields[1], fields[2]))

    return keys


def update_known_hosts(vm_keys):
    """Проверяем существующие ключи и безопасно обновляем файл."""

    additions = []

    for name, ip, lines in vm_keys:
        existing = find_existing_keys(ip)

        for line in lines:
            fields = line.split()

            if len(fields) < 3:
                continue

            key_type, key_data = fields[1], fields[2]
            key = (key_type, key_data)

            # Если ключ этого типа уже есть, проверяем совпадение.
            old_keys = {
                item for item in existing
                if item[0] == key_type
            }

            if old_keys:
                if key not in old_keys:
                    raise RuntimeError(
                        f"SSH HOST KEY CHANGED: {name} ({ip}), "
                        f"type {key_type}. "
                        "Verify the new fingerprint before updating."
                    )
                continue

            additions.append(line)

    if not additions:
        print("known_hosts is already up to date.")
        return

    KNOWN_HOSTS.parent.mkdir(
        parents=True,
        exist_ok=True,
        mode=0o700,
    )

    os.chmod(KNOWN_HOSTS.parent, 0o700)

    old_content = (
        KNOWN_HOSTS.read_text(encoding="utf-8")
        if KNOWN_HOSTS.exists()
        else ""
    )

    new_content = old_content

    if new_content and not new_content.endswith("\n"):
        new_content += "\n"

    new_content += "\n".join(additions) + "\n"

    fd, temp_path = tempfile.mkstemp(
        dir=KNOWN_HOSTS.parent,
        prefix="known_hosts."
    )

    try:
        with os.fdopen(fd, "w", encoding="utf-8") as file:
            file.write(new_content)

        os.chmod(temp_path, 0o600)
        os.replace(temp_path, KNOWN_HOSTS)

    finally:
        if os.path.exists(temp_path):
            os.unlink(temp_path)

    print(f"Updated: {KNOWN_HOSTS}")
    print(f"New SSH keys: {len(additions)}")


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--interval", type=int, default=5)

    args = parser.parse_args()

    try:
        vms = get_vm_ips()

        print(f"VMs found: {len(vms)}")

        vm_keys = []

        for name, ip in vms:
            keys = wait_for_ssh(
                name,
                ip,
                args.timeout,
                args.interval,
            )

            vm_keys.append((name, ip, keys))

        update_known_hosts(vm_keys)

        print("All SSH host keys processed successfully.")

    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

