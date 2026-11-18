variable "proxmox_api_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
}

variable "proxmox_insecure" {
  description = "Disable TLS certificate verification"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Proxmox node where VMs will be created"
  type        = string
  default     = "pve"
}

variable "template_id" {
  description = "Proxmox VM ID used as the source template"
  type        = number
}

variable "network_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

variable "datastore_id" {
  description = "Proxmox datastore for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "network_cidr" {
  description = "IPv4 subnet used by the VM network"
  type        = string
  default     = "192.168.122.0/24"

  validation {
    condition     = can(cidrnetmask(var.network_cidr))
    error_message = "network_cidr must be a valid IPv4 CIDR."
  }
}

variable "gateway" {
  description = "IPv4 gateway"
  type        = string
  default     = "192.168.122.1"

  validation {
    condition     = can(cidrnetmask("${var.gateway}/32"))
    error_message = "Gateway must be a valid IPv4 address."
  }

  validation {
    condition = try(
      cidrhost(
        "${var.gateway}/${split("/", var.network_cidr)[1]}",
        0
      ) == cidrhost(var.network_cidr, 0),
      false
    )
    error_message = "Gateway must belong to network_cidr."
  }

  validation {
    condition = try(
      var.gateway != cidrhost(var.network_cidr, 0) &&
      var.gateway != cidrhost(var.network_cidr, -1),
      false
    )
    error_message = "Gateway must not be the network or broadcast address."
  }
}

variable "vms" {
  description = "Virtual machines to create"

  type = map(object({
    cores  = number
    memory = number
    disk   = number
    ip     = string
  }))

  validation {
    condition     = length(var.vms) > 0
    error_message = "At least one VM must be defined."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      vm.cores >= 1 && vm.cores <= 32
    ])
    error_message = "VM cores must be between 1 and 32."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      vm.memory >= 512
    ])
    error_message = "VM memory must be at least 512 MB."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      vm.disk >= 5
    ])
    error_message = "VM disk size must be at least 5 GB."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      can(cidrnetmask(vm.ip))
    ])
    error_message = "Each VM IP must be a valid IPv4 CIDR, e.g. 192.168.122.201/24."
  }

  validation {
    condition = length(distinct([
      for vm in values(var.vms) :
      split("/", vm.ip)[0]
    ])) == length(var.vms)
    error_message = "Every VM must have a unique IPv4 address."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      try(
        split("/", vm.ip)[1] == split("/", var.network_cidr)[1] &&
        cidrhost(
          "${split("/", vm.ip)[0]}/${split("/", var.network_cidr)[1]}",
          0
        ) == cidrhost(var.network_cidr, 0) &&
        split("/", vm.ip)[0] != cidrhost(var.network_cidr, 0) &&
        split("/", vm.ip)[0] != cidrhost(var.network_cidr, -1),
        false
      )
    ])
    error_message = "Every VM IP must be a valid host address within network_cidr, using the same prefix length."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      try(
        split("/", vm.ip)[0] != var.gateway,
        false
      )
    ])
    error_message = "A VM IP must not be the same as the gateway."
  }
}

variable "vm_username" {
  description = "Linux user created by cloud-init"
  type        = string
  default     = "s-debi"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*[$]?$", var.vm_username))
    error_message = "Invalid Linux username."
  }
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key on Terraform controller"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"

  validation {
    condition     = fileexists(pathexpand(var.ssh_public_key_path))
    error_message = "SSH public key file does not exist."
  }
}

