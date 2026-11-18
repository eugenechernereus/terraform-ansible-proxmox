output "vm_id" {
  description = "Created VM ID"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "Created VM name"
  value       = proxmox_virtual_environment_vm.this.name
}

