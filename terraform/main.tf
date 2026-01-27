# ============================================================================
# Terraform Configuration
# ============================================================================
# Kubernetes cluster infrastructure on Proxmox VE
# - 1 control plane node on pve-1
# - 1 worker node on pve-1
# - 1 worker node on pve-2
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66.0"
    }
  }
}

# ============================================================================
# Proxmox Provider
# ============================================================================

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true
}

# ============================================================================
# Control Plane Node (pve-1)
# ============================================================================

resource "proxmox_virtual_environment_vm" "control_plane" {
  vm_id       = var.vm_start_id
  name        = "k8s-control-plane"
  description = "Kubernetes Control Plane Node"
  tags        = ["kubernetes", "control-plane"]
  node_name   = "pve-1"

  started = true
  on_boot = true

  boot_order = ["scsi0", "net0"]

  cpu {
    cores   = var.control_plane_cores
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.control_plane_memory
  }

  agent {
    enabled = true
    trim    = true
    type    = "virtio"
  }

  disk {
    datastore_id = "data-2"
    interface    = "scsi0"
    size         = var.control_plane_disk_size
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  network_device {
    bridge      = var.vm_bridge
    model       = "virtio"
    vlan_id     = var.vlan_id
    mac_address = var.control_plane_mac
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "${cidrhost(var.network_cidr, var.control_plane_ip)}/${split("/", var.network_cidr)[1]}"
        gateway = var.network_gateway
      }
    }

    dns {
      servers = var.network_dns_servers
    }

    user_account {
      username = var.vm_user
      password = var.vm_password
      keys     = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    }

    user_data_file_id = var.cloud_init_user_data_file_id
  }
}

# ============================================================================
# Worker Node on PVE-1 (same node as control plane)
# ============================================================================

resource "proxmox_virtual_environment_vm" "worker_pve1" {
  depends_on = [proxmox_virtual_environment_vm.control_plane]

  vm_id       = var.vm_start_id + 1
  name        = "k8s-worker-pve1"
  description = "Kubernetes Worker Node on PVE-1"
  tags        = ["kubernetes", "worker", "pve-1"]
  node_name   = "pve-1"

  started = true
  on_boot = true

  boot_order = ["scsi0", "net0"]

  cpu {
    cores   = var.worker_pve1_cores
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.worker_pve1_memory
  }

  agent {
    enabled = true
    trim    = true
    type    = "virtio"
  }

  disk {
    datastore_id = "data-2"
    interface    = "scsi0"
    size         = var.worker_pve1_disk_size
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  disk {
    datastore_id = "data-2"
    interface    = "scsi1"
    size         = var.worker_pve1_disk2_size
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  network_device {
    bridge      = var.vm_bridge
    model       = "virtio"
    vlan_id     = var.vlan_id
    mac_address = var.worker_pve1_mac
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "${cidrhost(var.network_cidr, var.worker_pve1_ip)}/${split("/", var.network_cidr)[1]}"
        gateway = var.network_gateway
      }
    }

    dns {
      servers = var.network_dns_servers
    }

    user_account {
      username = var.vm_user
      password = var.vm_password
      keys     = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    }

    user_data_file_id = var.cloud_init_user_data_file_id
  }
}

# ============================================================================
# Worker Node on PVE-2
# ============================================================================

resource "proxmox_virtual_environment_vm" "worker_pve2" {
  depends_on = [proxmox_virtual_environment_vm.control_plane]

  vm_id       = var.vm_start_id + 2
  name        = "k8s-worker-pve2"
  description = "Kubernetes Worker Node on PVE-2"
  tags        = ["kubernetes", "worker", "pve-2"]
  node_name   = "pve-2"

  started = true
  on_boot = true

  boot_order = ["scsi0", "net0"]

  cpu {
    cores   = var.worker_pve2_cores
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.worker_pve2_memory
  }

  agent {
    enabled = true
    trim    = true
    type    = "virtio"
  }

  disk {
    datastore_id = "data-2"
    interface    = "scsi0"
    size         = var.worker_pve2_disk_size
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  disk {
    datastore_id = "data-2"
    interface    = "scsi1"
    size         = var.worker_pve2_disk2_size
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  network_device {
    bridge      = var.vm_bridge
    model       = "virtio"
    vlan_id     = var.vlan_id
    mac_address = var.worker_pve2_mac
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "${cidrhost(var.network_cidr, var.worker_pve2_ip)}/${split("/", var.network_cidr)[1]}"
        gateway = var.network_gateway
      }
    }

    dns {
      servers = var.network_dns_servers
    }

    user_account {
      username = var.vm_user
      password = var.vm_password
      keys     = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    }

    user_data_file_id = var.cloud_init_user_data_file_id
  }
}

# ============================================================================
# Outputs
# ============================================================================

output "cluster_summary" {
  description = "Kubernetes cluster summary"
  value = {
    control_plane = {
      name   = proxmox_virtual_environment_vm.control_plane.name
      vm_id  = proxmox_virtual_environment_vm.control_plane.vm_id
      node   = proxmox_virtual_environment_vm.control_plane.node_name
      ip     = cidrhost(var.network_cidr, var.control_plane_ip)
      cores  = var.control_plane_cores
      memory = "${var.control_plane_memory / 1024} GB"
    }
    worker_pve1 = {
      name   = proxmox_virtual_environment_vm.worker_pve1.name
      vm_id  = proxmox_virtual_environment_vm.worker_pve1.vm_id
      node   = proxmox_virtual_environment_vm.worker_pve1.node_name
      ip     = cidrhost(var.network_cidr, var.worker_pve1_ip)
      cores  = var.worker_pve1_cores
      memory = "${var.worker_pve1_memory / 1024} GB"
    }
    worker_pve2 = {
      name   = proxmox_virtual_environment_vm.worker_pve2.name
      vm_id  = proxmox_virtual_environment_vm.worker_pve2.vm_id
      node   = proxmox_virtual_environment_vm.worker_pve2.node_name
      ip     = cidrhost(var.network_cidr, var.worker_pve2_ip)
      cores  = var.worker_pve2_cores
      memory = "${var.worker_pve2_memory / 1024} GB"
    }
  }
}

output "control_plane_ip" {
  description = "Control plane IP address"
  value       = cidrhost(var.network_cidr, var.control_plane_ip)
}

output "worker_ips" {
  description = "Worker node IP addresses"
  value = {
    pve1 = cidrhost(var.network_cidr, var.worker_pve1_ip)
    pve2 = cidrhost(var.network_cidr, var.worker_pve2_ip)
  }
}

output "vm_ids" {
  description = "All VM IDs"
  value = {
    control_plane = proxmox_virtual_environment_vm.control_plane.vm_id
    worker_pve1   = proxmox_virtual_environment_vm.worker_pve1.vm_id
    worker_pve2   = proxmox_virtual_environment_vm.worker_pve2.vm_id
  }
}
