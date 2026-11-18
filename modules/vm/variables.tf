variable "name" {
  description = "Virtual machine name"
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox node"
  type        = string
}

variable "template_id" {
  description = "Source template ID"
  type        = number
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
}

variable "datastore_id" {
  description = "Datastore for VM disk"
  type        = string
}

variable "gateway" {
  description = "IPv4 gateway"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
}

variable "memory" {
  description = "RAM in MB"
  type        = number
}

variable "disk" {
  description = "Disk size in GB"
  type        = number
}

variable "ip" {
  description = "IPv4 address with prefix"
  type        = string
}

variable "vm_username" {
  description = "Linux user"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

