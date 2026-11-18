output "template" {
  description = "Source VM template"

  value = {
    name   = data.proxmox_vm.template.name
    vm_id  = data.proxmox_vm.template.id
    status = data.proxmox_vm.template.status
  }
}

output "vms" {
  description = "Created virtual machines"

  value = {
    for name, vm in module.vm :
    name => {
      vm_id = vm.vm_id
      ip    = local.vm_ips[name]
    }
  }
}

output "vm_ips" {
  description = "VM IPv4 addresses without CIDR prefix"

  value = {
    for name, ip in local.vm_ips :
    name => split("/", ip)[0]
  }
}

output "ansible_config" {
  description = "Connection settings for Ansible"

  value = {
    user = var.vm_username
  }
}

