# ============================================================================
# Proxmox Provider Configuration
# ============================================================================

variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (format: user@realm!tokenname)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_username" {
  description = "Proxmox username for password authentication (alternative to token)"
  type        = string
  default     = null
}

variable "proxmox_password" {
  description = "Proxmox password for password authentication (alternative to token)"
  type        = string
  default     = null
  sensitive   = true
}

# ============================================================================
# VM Template Configuration
# ============================================================================

variable "template_name" {
  description = "Cloud-init template image name"
  type        = string
}

variable "template_vm_id_pve1" {
  description = "Template VM ID on pve-1 node"
  type        = number
  default     = 9000
}

variable "template_vm_id_pve2" {
  description = "Template VM ID on pve-2 node"
  type        = number
  default     = 9001
}

# ============================================================================
# VM ID Configuration
# ============================================================================

variable "vm_start_id" {
  description = "Starting VM ID for Kubernetes cluster VMs"
  type        = number
  default     = 900
}

# ============================================================================
# Control Plane Configuration (pve-1)
# ============================================================================

variable "control_plane_cores" {
  description = "CPU cores for control plane node"
  type        = number
  default     = 4
}

variable "control_plane_memory" {
  description = "Memory for control plane node (MB)"
  type        = number
  default     = 6144
}

variable "control_plane_disk_size" {
  description = "Disk size for control plane node (GB)"
  type        = number
  default     = 50
}

# ============================================================================
# Worker Node Configuration - PVE-1
# ============================================================================

variable "worker_pve1_cores" {
  description = "CPU cores for worker on pve-1 (same node as control plane)"
  type        = number
  default     = 10
}

variable "worker_pve1_memory" {
  description = "Memory for worker on pve-1 (MB)"
  type        = number
  default     = 22528
}

variable "worker_pve1_disk_size" {
  description = "Primary disk size for worker on pve-1 (GB)"
  type        = number
  default     = 800
}

variable "worker_pve1_disk2_size" {
  description = "Secondary disk size for worker on pve-1 (GB)"
  type        = number
  default     = 1900
}

# ============================================================================
# Worker Node Configuration - PVE-2
# ============================================================================

variable "worker_pve2_cores" {
  description = "CPU cores for worker on pve-2"
  type        = number
  default     = 14
}

variable "worker_pve2_memory" {
  description = "Memory for worker on pve-2 (MB)"
  type        = number
  default     = 28672
}

variable "worker_pve2_disk_size" {
  description = "Primary disk size for worker on pve-2 (GB)"
  type        = number
  default     = 800
}

variable "worker_pve2_disk2_size" {
  description = "Secondary disk size for worker on pve-2 (GB)"
  type        = number
  default     = 1900
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
  description = "VLAN ID (optional)"
  type        = number
  default     = null
}

variable "network_cidr" {
  description = "Network CIDR block (e.g., 192.168.1.0/24)"
  type        = string
}

variable "control_plane_ip" {
  description = "Static IP address for control plane (last octet or full IP)"
  type        = string
  default     = "210"
}

variable "control_plane_mac" {
  description = "MAC address for control plane node"
  type        = string
  default     = "BC:24:11:00:00:01"
}

variable "worker_pve1_ip" {
  description = "Static IP address for worker on pve-1 (last octet or full IP)"
  type        = string
  default     = "211"
}

variable "worker_pve1_mac" {
  description = "MAC address for worker on pve-1"
  type        = string
  default     = "BC:24:11:00:00:02"
}

variable "worker_pve2_ip" {
  description = "Static IP address for worker on pve-2 (last octet or full IP)"
  type        = string
  default     = "212"
}

variable "worker_pve2_mac" {
  description = "MAC address for worker on pve-2"
  type        = string
  default     = "BC:24:11:00:00:03"
}
