module "vm" {
  source   = "./modules/vm"
  for_each = var.vms

  name           = each.key
  proxmox_node   = var.proxmox_node
  template_id    = data.proxmox_vm.template.id
  network_bridge = var.network_bridge
  datastore_id   = var.datastore_id
  gateway        = var.gateway

  cores  = each.value.cores
  memory = each.value.memory
  disk   = each.value.disk
  ip     = each.value.ip

  vm_username         = var.vm_username
  ssh_public_key_path = var.ssh_public_key_path
}

