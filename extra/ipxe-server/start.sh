#!/usr/bin/env bash
set -e

# ==========================================
# Petra Homelab Bootstrap Server (iPXE/TFTP)
# ==========================================

# 1. Configuration & Detection
# ----------------------------
cd "$(dirname "$0")"

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
MY_IP=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
SUBNET=$(echo $MY_IP | cut -d'.' -f1-3).0
WorkDir=$(pwd)

echo "=== Petra Homelab Bootstrap Server ==="
echo "Host IP:   $MY_IP"
echo "Interface: $INTERFACE"
echo "Subnet:    $SUBNET"

if [ -z "$INTERFACE" ]; then
    echo "Error: Could not detect network interface. Please set INTERFACE manually."
    exit 1
fi

mkdir -p tftp

# 2. Prepare Binaries
# -------------------
if [ ! -f "tftp/ipxe.efi" ]; then
    echo "[-] Downloading ipxe.efi..."
    wget -q -O tftp/ipxe.efi http://boot.ipxe.org/ipxe.efi
fi

if [ ! -f "tftp/undionly.kpxe" ]; then
    echo "[-] Downloading undionly.kpxe..."
    wget -q -O tftp/undionly.kpxe http://boot.ipxe.org/undionly.kpxe
fi

# 3. Configure iPXE Script
# ------------------------
cat <<EOF > http/boot.ipxe
#!ipxe
echo Loading Petra Homelab iPXE config...
set server_ip $MY_IP
set http_url http://\${server_ip}:8000

# Clear any previous images
imgfree

# Detect VM purpose
iseq \${net0/mac} bc:24:11:00:00:11 && set hostname k8s-cp-01 && goto boot_ubuntu ||
iseq \${net0/mac} bc:24:11:00:00:12 && set hostname k8s-cp-02 && goto boot_ubuntu ||
iseq \${net0/mac} bc:24:11:00:00:13 && set hostname k8s-cp-03 && goto boot_ubuntu ||
iseq \${net0/mac} bc:24:11:00:00:21 && set hostname k8s-w-01 && goto boot_ubuntu ||
iseq \${net0/mac} bc:24:11:00:00:22 && set hostname k8s-w-02 && goto boot_ubuntu ||
iseq \${net0/mac} bc:24:11:00:00:23 && set hostname k8s-w-03 && goto boot_ubuntu ||

:start
menu Boot Menu for Petra Homelab (MAC: \${net0/mac})
item --gap --             ---------------------------------
item install_k8s_control  Installer Control Plane (Ubuntu 22.04)
item install_k8s_worker   Installer Worker Node (Ubuntu 22.04)
item shell                Drop to iPXE shell
item exit                 Exit to BIOS
choose --timeout 10000 --default install_k8s_control target && goto \${target}

:install_k8s_control
set hostname k8s-control-plane-manual
goto boot_ubuntu

:install_k8s_worker
set hostname k8s-worker-manual
goto boot_ubuntu

:boot_ubuntu
echo Starting Ubuntu installation for \${hostname}...
set iso_url \${http_url}/images/ubuntu-22.04.5-live-server-amd64.iso
echo Fetching kernel: \${http_url}/images/vmlinuz
kernel \${http_url}/images/vmlinuz initrd=initrd ip=dhcp url=\${iso_url} autoinstall ds=nocloud-net;s=\${http_url}/cloud-init/ cloud-config-url=\${http_url}/cloud-init/user-data hostname=\${hostname} || goto error
echo Fetching initrd: \${http_url}/images/initrd
initrd \${http_url}/images/initrd || goto error
echo Booting...
boot || goto error

:error
echo Error occurred!
imgstat
echo Waiting 10 seconds before shell...
sleep 10
shell

:shell
shell

:exit
exit
EOF

cp http/boot.ipxe tftp/boot.ipxe

# 4. Generate dnsmasq Configuration
# ---------------------------------
rm -f dnsmasq.conf
echo "[-] Generating dnsmasq.conf..."
cat <<EOF > dnsmasq.conf
user=root
interface=$INTERFACE
bind-interfaces
port=0
log-dhcp
log-queries

# ProxyDHCP
dhcp-range=$SUBNET,proxy,255.255.255.0
dhcp-authoritative

# Critical options for ProxyDHCP
dhcp-option=66,"$MY_IP"
dhcp-option=150,$MY_IP
dhcp-no-override

# Matchers
dhcp-userclass=set:ipxe,iPXE
dhcp-match=set:ipxe,175
dhcp-match=set:efi-x86_64,option:client-arch,7
dhcp-match=set:efi-x86_64,option:client-arch,9
dhcp-match=set:bios,option:client-arch,0

# PXE Menu
pxe-service=tag:!ipxe,x86PC, "Boot (BIOS)", undionly.kpxe
pxe-service=tag:!ipxe,BC_EFI, "Boot (UEFI)", ipxe.efi
pxe-service=tag:!ipxe,X86-64_EFI, "Boot (UEFI)", ipxe.efi

# Boot directives
dhcp-boot=tag:ipxe,boot.ipxe,,$MY_IP
dhcp-option-force=tag:ipxe,67,boot.ipxe

# TFTP
enable-tftp
tftp-root=$WorkDir/tftp
tftp-no-blocksize
tftp-port-range=10000,10100
EOF

# 5. Network & Firewall (OPEN EVERYTHING)
# --------------------------------------
echo "[-] Disabling RP filter..."
sudo sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
sudo sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null
sudo sysctl -w net.ipv4.conf.$INTERFACE.rp_filter=0 >/dev/null

echo "[-] Stopping firewalls..."
sudo systemctl stop ufw 2>/dev/null || true
sudo systemctl stop firewalld 2>/dev/null || true
sudo systemctl stop nftables 2>/dev/null || true

echo "[-] Flushing ALL iptables..."
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X
sudo nft flush ruleset 2>/dev/null || true
sudo ebtables -F 2>/dev/null || true
sudo ebtables -X 2>/dev/null || true

# 6. Start Services
# -----------------
echo "[-] Starting HTTP server (Multithreaded)..."
cd http
pkill -f "python3 -u -c.*ThreadingHTTPServer" || true
# Use a small script to start a multithreaded server
python3 -u -c '
import http.server, socketserver
class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    pass
server_address = ("0.0.0.0", 8000)
httpd = ThreadingHTTPServer(server_address, http.server.SimpleHTTPRequestHandler)
print(f"Serving HTTP on {server_address[0]} port {server_address[1]}...")
httpd.serve_forever()
' > /tmp/http_server.log 2>&1 &
HTTP_PID=$!
cd ..

cleanup() {
    echo "[-] Stopping HTTP server..."
    kill $HTTP_PID 2>/dev/null || true
}
trap cleanup EXIT

echo "[-] Starting dnsmasq..."
sudo dnsmasq -C dnsmasq.conf -d
