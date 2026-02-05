# Terraform Configuration

terraform {
  required_version = ">= 1.3"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true
}

# Control Plane Nodes

resource "proxmox_virtual_environment_vm" "control_plane" {
  for_each = var.control_planes

  vm_id       = each.value.vm_id
  name        = each.key
  description = "Kubernetes Control Plane Node"
  tags        = ["kubernetes", "control-plane"]
  node_name   = each.value.node_name

  started = true
  on_boot = true

  boot_order = ["scsi0", "net0"]

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  agent {
    enabled = true
    trim    = true
    type    = "virtio"
  }

  dynamic "disk" {
    for_each = each.value.disks
    content {
      datastore_id = disk.value.datastore
      interface    = disk.value.interface
      size         = disk.value.size
      file_format  = "raw"
      ssd          = true
      discard      = "on"
    }
  }

  network_device {
    bridge      = var.vm_bridge
    model       = "virtio"
    vlan_id     = var.vlan_id
    mac_address = each.value.mac_address
  }
}

# Worker Nodes

resource "proxmox_virtual_environment_vm" "worker" {
  for_each = var.workers

  vm_id       = each.value.vm_id
  name        = each.key
  description = "Kubernetes Worker Node"
  tags        = ["kubernetes", "worker", each.value.node_name]
  node_name   = each.value.node_name

  started = true
  on_boot = true

  boot_order = ["scsi0", "net0"]

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  agent {
    enabled = true
    trim    = true
    type    = "virtio"
  }

  dynamic "disk" {
    for_each = each.value.disks
    content {
      datastore_id = disk.value.datastore
      interface    = disk.value.interface
      size         = disk.value.size
      file_format  = "raw"
      ssd          = true
      discard      = "on"
    }
  }

  network_device {
    bridge      = var.vm_bridge
    model       = "virtio"
    vlan_id     = var.vlan_id
    mac_address = each.value.mac_address
  }
}

# Outputs

output "cluster_nodes" {
  description = "Kubernetes cluster nodes summary"
  value = {
    control_planes = {
      for name, node in proxmox_virtual_environment_vm.control_plane : name => {
        vm_id  = node.vm_id
        node   = node.node_name
        ip     = cidrhost(var.network_cidr, var.control_planes[name].ip)
        cores  = var.control_planes[name].cores
        memory = "${var.control_planes[name].memory / 1024} GB"
      }
    }
    workers = {
      for name, node in proxmox_virtual_environment_vm.worker : name => {
        vm_id  = node.vm_id
        node   = node.node_name
        ip     = cidrhost(var.network_cidr, var.workers[name].ip)
        cores  = var.workers[name].cores
        memory = "${var.workers[name].memory / 1024} GB"
      }
    }
  }
}

output "control_plane_ips" {
  description = "Control plane IP addresses"
  value = {
    for name, config in var.control_planes : name => cidrhost(var.network_cidr, config.ip)
  }
}

output "worker_ips" {
  description = "Worker node IP addresses"
  value = {
    for name, config in var.workers : name => cidrhost(var.network_cidr, config.ip)
  }
}
