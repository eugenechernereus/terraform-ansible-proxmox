mock_provider "proxmox" {
  override_during = plan

  mock_data "proxmox_vm" {
    defaults = {
      template = true
      name     = "test-template"
      status   = "stopped"
    }
  }
}

# Корректная сеть и три VM
run "valid_network" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    proxmox_node      = "pve"
    template_id       = 9000

    network_bridge = "vmbr0"
    datastore_id   = "local-lvm"
    network_cidr   = "192.168.122.0/24"
    gateway        = "192.168.122.1"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.201/24"
      }
      app-01 = {
        cores  = 2
        memory = 2048
        disk   = 6
        ip     = "192.168.122.202/24"
      }
      db-01 = {
        cores  = 1
        memory = 2048
        disk   = 7
        ip     = "192.168.122.203/24"
      }
    }
  }

  # Проверяем количество виртуальных машин
  assert {
    condition     = length(output.vms) == 3
    error_message = "Expected exactly 3 VMs."
  }

  # Проверяем имена виртуальных машин
  assert {
    condition = toset(keys(output.vms)) == toset([
      "web-01",
      "app-01",
      "db-01"
    ])
    error_message = "VM names do not match the expected set."
  }

  # Проверяем IP виртуальных машин
  assert {
    condition     = output.vms["web-01"].ip == "192.168.122.201/24"
    error_message = "web-01 has an unexpected IP address."
  }

  assert {
    condition     = output.vms["app-01"].ip == "192.168.122.202/24"
    error_message = "app-01 has an unexpected IP address."
  }

  assert {
    condition     = output.vms["db-01"].ip == "192.168.122.203/24"
    error_message = "db-01 has an unexpected IP address."
  }

  # Проверяем, что используется ожидаемый шаблон
  assert {
    condition     = output.template.vm_id == 9000
    error_message = "Unexpected Proxmox template ID."
  }
}

# Две VM с одним IP
run "duplicate_ips" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.122.1"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.201/24"
      }
      app-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.201/24"
      }
    }
  }

  expect_failures = [var.vms]
}

# IP из другой подсети
run "ip_outside_network" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.122.1"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.123.201/24"
      }
    }
  }

  expect_failures = [var.vms]
}

# VM использует другую маску
run "wrong_prefix" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.122.1"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.201/16"
      }
    }
  }

  expect_failures = [var.vms]
}

# IP совпадает с gateway
run "ip_equals_gateway" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.122.1"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.1/24"
      }
    }
  }

  expect_failures = [var.vms]
}

# Тест пустой карты VM
run "empty_vms" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.122.1"

    vms = {}
  }

  expect_failures = [var.vms]
}

# Тест некорректного IP
run "invalid_ip" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.122.1"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.999/24"
      }
    }
  }

  expect_failures = [var.vms]
}

# Тест адреса сети
run "network_address" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.122.1"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.0/24"
      }
    }
  }

  expect_failures = [var.vms]
}

# Тест broadcast-адреса
run "broadcast_address" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.122.1"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.255/24"
      }
    }
  }

  expect_failures = [var.vms]
}

# Gateway за пределами подсети
run "gateway_outside_network" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.123.1"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.201/24"
      }
    }
  }

  expect_failures = [var.gateway]
}

# Некорректный IPv4 у gateway
run "invalid_gateway" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.122.999"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.201/24"
      }
    }
  }

  expect_failures = [var.gateway]
}

# Gateway совпадает с адресом сети
run "gateway_is_network_address" {
  command = plan

  variables {
    proxmox_endpoint  = "https://proxmox.example.test:8006/"
    proxmox_api_token = "test-token"
    template_id       = 9000

    network_cidr = "192.168.122.0/24"
    gateway      = "192.168.122.0"

    vms = {
      web-01 = {
        cores  = 2
        memory = 1024
        disk   = 5
        ip     = "192.168.122.201/24"
      }
    }
  }

  expect_failures = [var.gateway]
}

