# Kubernetes Cluster on Proxmox VE

This Terraform configuration deploys a Kubernetes cluster infrastructure on Proxmox VE with a clean, node-based architecture.

## Architecture

### Cluster Layout

| Node | VM Name | Role | Cores | Memory | IP |
|------|---------|------|-------|--------|-----|
| pve-1 | k8s-control-plane | Control Plane | 4 | 6 GB | 192.168.1.210 |
| pve-1 | k8s-worker-pve1 | Worker | 10 | 22 GB | 192.168.1.211 |
| pve-2 | k8s-worker-pve2 | Worker | 14 | 28 GB | 192.168.1.212 |

### Resource Distribution

- **pve-1**: 14 cores total, 28 GB RAM total
- **pve-2**: 14 cores total, 28 GB RAM total

## Prerequisites

1. Proxmox VE 8.x cluster with nodes `pve-1` and `pve-2`
2. Ubuntu cloud image template on both nodes
3. Proxmox API token with appropriate permissions
4. Terraform >= 1.0

## Configuration

### Required Variables

Create a `terraform.tfvars` file or set these variables:

```hcl
# Proxmox API
proxmox_api_url          = "https://192.168.1.201:8006/"
proxmox_api_token_id     = "terraform-prov@pve!tf"
proxmox_api_token_secret = "your-secret-here"

# VM Template
template_name = "local:jammy-server-cloudimg-amd64.img"

# Network
network_cidr    = "192.168.1.0/24"
network_gateway = "192.168.1.254"

# Cloud-Init
vm_user     = "ubuntu"
vm_password = "your-password"
```

### Customization

You can customize each node's resources independently:

```hcl
# Control Plane (pve-1)
control_plane_cores  = 4
control_plane_memory = 6144  # MB

# Worker on pve-1
worker_pve1_cores  = 10
worker_pve1_memory = 22528  # MB

# Worker on pve-2
worker_pve2_cores  = 14
worker_pve2_memory = 28672  # MB
```

## Usage

### Initialize Terraform

```bash
terraform init
```

### Plan Deployment

```bash
terraform plan
```

### Deploy Cluster

```bash
terraform apply
```

### View Cluster Information

```bash
terraform output cluster_summary
```

### Destroy Cluster

```bash
terraform destroy
```

## Outputs

- `cluster_summary`: Complete cluster information (nodes, IPs, resources)
- `control_plane_ip`: Control plane IP address
- `worker_ips`: Worker node IP addresses
- `vm_ids`: All VM IDs

## File Structure

```
terraform/
├── main.tf           # Main infrastructure configuration
├── variables.tf      # Variable definitions
├── terraform.tfvars  # Variable values (customize this)
└── README.md         # This file
```

## Notes

- VMs are configured with cloud-init for initial setup
- QEMU guest agent is enabled on all VMs
- All VMs use SCSI disks with SSD emulation
- Network uses virtio drivers for best performance
- VMs are set to start automatically on boot

## Next Steps

After deployment, you'll need to:

1. SSH into the control plane node
2. Install Kubernetes (kubeadm, kubelet, kubectl)
3. Initialize the cluster on the control plane
4. Join worker nodes to the cluster

## License

This configuration is provided as-is for infrastructure deployment.

