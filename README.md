# petra-homelab-bootstrap

Repo to set up my homelab Kubernetes cluster on Proxmox, from nothing up to a working kubeconfig.

Basically it's 3 steps:

1. **Terraform** creates the VMs on Proxmox (`terraform/proxmox`)
2. The VMs boot over PXE from an **iPXE server** running on my PC, which installs Ubuntu 22.04 automatically (`extra/ipxe-server`)
3. **Kubespray** installs Kubernetes on the VMs (`kubespray`)

There is also `terraform/authentik` to configure Authentik, but that's separate from the cluster.

## The cluster

| Name     | Role          | IP            | MAC               |
|----------|---------------|---------------|-------------------|
| k8s-cp-1 | control plane | 192.168.1.211 | BC:24:11:00:00:11 |
| k8s-cp-2 | control plane | 192.168.1.212 | BC:24:11:00:00:12 |
| k8s-cp-3 | control plane | 192.168.1.213 | BC:24:11:00:00:13 |
| k8s-w-1  | worker        | 192.168.1.221 | BC:24:11:00:00:21 |
| k8s-w-2  | worker        | 192.168.1.222 | BC:24:11:00:00:22 |
| k8s-w-3  | worker        | 192.168.1.223 | BC:24:11:00:00:23 |

- API server VIP (kube-vip): `192.168.1.210`
- etcd runs on the control planes
- CNI: Calico in BGP mode (no IPIP / VXLAN)
- Hardening enabled: secrets encrypted in etcd, audit log, Pod Security Admission set to `baseline`

IPs come from the router's DHCP (static lease for each MAC). MACs are set in `terraform.tfvars`
and the iPXE script uses them to know which hostname to give to each VM.

## Tree

```
.
├── flake.nix                 # dev environment (terraform, ansible, task, dnsmasq...)
├── Taskfile.yml              # global tasks
├── terraform/
│   ├── proxmox/              # VM creation
│   └── authentik/            # Authentik config
├── extra/ipxe-server/        # PXE server (dnsmasq in proxyDHCP + TFTP + HTTP)
│   ├── start.sh
│   └── http/
│       ├── cloud-init/       # Ubuntu autoinstall
│       └── images/           # iso + vmlinuz + initrd (not in git)
├── kubespray/
│   ├── Taskfile.yml
│   ├── inventory/petra_cluster/
│   └── kubespray/            # kubespray submodule
└── docs/
```

## Requirements

- Nix with flakes, and direnv (or `nix develop`)
- A Proxmox API token
- My SSH key (the one in `extra/ipxe-server/http/cloud-init/user-data`)
- Being on the same network as the VMs (the PXE server answers in proxyDHCP)

Files to create by hand (they are in `.gitignore`):

- `terraform/proxmox/terraform.tfvars`: API URL, token id, `network_cidr`, and the list of VMs
- `terraform/proxmox/.env`: `export TF_VAR_proxmox_api_token_secret=...`
- `extra/ipxe-server/http/images/`: the Ubuntu 22.04.5 iso + `vmlinuz` and `initrd` extracted from the iso (`casper/` folder)

## Useful commands

From the repo root:

```bash
direnv allow                      # load the nix env

task ipxe:start                   # start the PXE server
task terraform:proxmox:apply      # create the VMs
task kubespray:install            # install the cluster
```

In `terraform/proxmox`:

```bash
task tf                           # init + plan + apply
task tf-destroy                   # delete the VMs
```

In `kubespray`:

```bash
task init                         # submodule + python venv (only once)
task ping                         # ssh test on all nodes
task deploy                       # install the cluster
task reset                        # remove k8s from the nodes
task get-kubeconfig               # get the kubeconfig into ~/.kube/config
task reconfigure-node NODE=k8s-w-1
task remove-node NODE=k8s-w-1
```

## Reinstall the cluster

See [docs/reinstall-cluster.md](docs/reinstall-cluster.md).
