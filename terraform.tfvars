proxmox_endpoint = "https://192.168.122.105:8006/"

proxmox_node = "pve"

template_id = 9000

vm_username         = "s-debi"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"

network_bridge = "vmbr0"
datastore_id   = "local-lvm"

network_cidr = "192.168.122.0/24"
gateway      = "192.168.122.1"

vms = {
  db-01 = {
    cores  = 1
    memory = 2048
    disk   = 7
    ip     = "192.168.122.203/24"
  }


  app-01 = {
    cores  = 2
    memory = 2048
    disk   = 6
    ip     = "192.168.122.202/24"
  }

  web-01 = {
    cores  = 2
    memory = 1024
    disk   = 5
    ip     = "192.168.122.201/24"
  }
}

