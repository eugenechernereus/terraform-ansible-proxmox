locals {
  vm_ips = {
    for name, vm in var.vms :
    name => vm.ip
  }

  #  network_address   = cidrhost(var.network_cidr, 0)
  #  broadcast_address = cidrhost(var.network_cidr, -1)
}

