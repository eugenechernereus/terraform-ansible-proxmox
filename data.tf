data "proxmox_vm" "template" {
  node_name = var.proxmox_node
  id        = var.template_id

  lifecycle {
    postcondition {
      condition     = self.template
      error_message = "The specified template_id is not a Proxmox VM template."
    }
  }
}

