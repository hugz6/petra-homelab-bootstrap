# ============================================================================
# Proxmox Provider Configuration
# ============================================================================

variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_username" {
  description = "Proxmox username"
  type        = string
  default     = null
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  default     = null
  sensitive   = true
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "vm_bridge" {
  description = "Proxmox network bridge interface"
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "VLAN ID"
  type        = number
  default     = null
}

variable "network_cidr" {
  description = "Network CIDR block"
  type        = string
}

# ============================================================================
# Node Configuration
# ============================================================================

variable "vm_start_id" {
  description = "Base ID for VMs if not specified"
  type        = number
  default     = 900
}

variable "control_planes" {
  description = "Map of control plane nodes with their specific configuration"
  type = map(object({
    node_name = string
    vm_id     = number
    cores     = number
    memory    = number
    disks = list(object({
      size      = number
      datastore = optional(string, "data-2")
      interface = string
    }))
    ip          = string
    mac_address = string
  }))
  default = {
    "k8s-cp-1" = {
      node_name = "pve-1"
      vm_id     = 900
      cores     = 4
      memory    = 6144
      disks = [
        { size = 50, datastore = "data-2", interface = "scsi0" }
      ]
      ip          = "210"
      mac_address = "BC:24:11:00:00:01"
    }
  }
}

variable "workers" {
  description = "Map of worker nodes with their specific configuration"
  type = map(object({
    node_name = string
    vm_id     = number
    cores     = number
    memory    = number
    disks = list(object({
      size      = number
      datastore = optional(string, "data-2")
      interface = string
    }))
    ip          = string
    mac_address = string
  }))
  default = {
    "k8s-w-1" = {
      node_name = "pve-1"
      vm_id     = 901
      cores     = 10
      memory    = 22528
      disks = [
        { size = 800, datastore = "data-2", interface = "scsi0" },
        { size = 1900, datastore = "data-2", interface = "scsi1" }
      ]
      ip          = "211"
      mac_address = "BC:24:11:00:00:02"
    }
    "k8s-w-2" = {
      node_name = "pve-2"
      vm_id     = 902
      cores     = 14
      memory    = 28672
      disks = [
        { size = 800, datastore = "data-2", interface = "scsi0" },
        { size = 1900, datastore = "data-2", interface = "scsi1" }
      ]
      ip          = "212"
      mac_address = "BC:24:11:00:00:03"
    }
  }
}
