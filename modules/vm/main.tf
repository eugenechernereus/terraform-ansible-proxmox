resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.proxmox_node
  machine   = "q35"
  on_boot   = false

  clone {
    vm_id = var.template_id
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  network_device {
    bridge = var.network_bridge
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk
  }

  initialization {

    user_account {
      username = var.vm_username

      keys = [
        trimspace(file(pathexpand(var.ssh_public_key_path)))
      ]
    }

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
    }
  }
}

