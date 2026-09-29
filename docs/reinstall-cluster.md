# Cluster reinstall

How to redo everything from scratch: delete the VMs, recreate them, Ubuntu installs over PXE, then Kubespray.

Takes about 1h (Kubespray is the longest part).

**Warning: this deletes everything in the cluster (Longhorn disks included).** Make a backup first if needed.

## 0. Before starting

Check that these files exist (see the README):

- `terraform/proxmox/terraform.tfvars`
- `terraform/proxmox/.env`
- `extra/ipxe-server/http/images/` with the iso, `vmlinuz` and `initrd`

Then load the environment:

```bash
cd petra-homelab-bootstrap
direnv allow   # or nix develop
```

## 1. Delete the old VMs

```bash
cd terraform/proxmox
task tf-destroy
```

Why delete the VMs instead of just doing `task reset`? The VMs boot on the disk first (`scsi0`)
then on the network (`net0`). So to make them boot over PXE again they need an empty disk.

## 2. Start the PXE server

In another terminal, at the repo root:

```bash
task ipxe:start
```

The script asks for the sudo password (for dnsmasq). Leave it running during the whole Ubuntu install.

Warning: the script stops the firewall and flushes the iptables rules of the PC. Remember to start it again after.

## 3. Recreate the VMs

```bash
cd terraform/proxmox
task tf
```

Terraform shows the plan then asks for confirmation.

The VMs start on their own, boot over PXE and install Ubuntu. You can follow it in the Proxmox console.
If a VM shows the iPXE menu instead of starting the install, its MAC is not in `boot.ipxe`.

At the end of the install the VMs reboot on their disk. When they are all up, you can stop the PXE server
(`Ctrl+C`).

## 4. Clean the known_hosts

The VMs have new SSH keys, and since we use `StrictHostKeyChecking=accept-new`, Ansible will refuse
to connect if the old keys are still there.

```bash
for ip in 211 212 213 221 222 223; do ssh-keygen -R 192.168.1.$ip; done
```

## 5. Install Kubernetes

```bash
cd kubespray
task init     # only if the venv doesn't exist yet
task ping     # all nodes must answer SUCCESS
task deploy
```

`task deploy` is long (30-45 min). If it fails on only one node, you can rerun it on that node only:

```bash
task reconfigure-node NODE=k8s-w-2
```

## 6. Get the kubeconfig

```bash
task get-kubeconfig
```

It copies `admin.conf` from the first control plane to `~/.kube/config` and points it to the VIP `192.168.1.210`.

## 7. Check

```bash
kubectl get nodes
kubectl get pods -A
```

The 6 nodes must be `Ready` and no pod in `CrashLoopBackOff`.

## Known issues

- **The VM doesn't boot over PXE**: check that the PXE server is running and that the PC is on the same network.
  dnsmasq logs are shown in the terminal, you should see the DHCP requests from the VM.
- **Ubuntu install doesn't start / iPXE error**: check that `vmlinuz` and `initrd` are in
  `http/images/`. HTTP server logs are in `/tmp/http_server.log`.
- **`task ping` fails with "Host key verification failed"**: redo step 4.
- **`kubectl` doesn't answer**: check that the VIP answers (`ping 192.168.1.210`), otherwise look at kube-vip
  on the control planes.

## Next

Do the ArgoCD bootstrap.
