#!/bin/bash
set -e

# ==========================================
# Petra Homelab Bootstrap Server (iPXE/TFTP)
# ==========================================

# 1. Configuration & Detection
# ----------------------------
# Ensure we are in the script's directory
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
# Inject the dynamic server IP into the iPXE script
sed -i "s|^set server_ip .*|set server_ip $MY_IP|g" http/boot.ipxe

# Copy to TFTP root (TFTP is more reliable for the initial chainload than HTTP)
cp http/boot.ipxe tftp/boot.ipxe

# 4. Generate dnsmasq Configuration
# ---------------------------------
if [ ! -f "dnsmasq.conf" ]; then

    echo "[-] Generating dnsmasq.conf..."
    cat <<EOF > dnsmasq.conf
# --- General ---
interface=$INTERFACE
bind-dynamic 
port=0
log-dhcp

# --- ProxyDHCP Mode ---
# We don't hand out IPs (the Box does that), we only provide boot info.
dhcp-range=$SUBNET,proxy,255.255.255.0
dhcp-authoritative

# --- Critical Options ---
# Option 66 (Next Server): Tells the client WE are the boot server, not the Box.
dhcp-option=66,"$MY_IP"

# --- Client Detection (Matchers) ---
# Detect if the request comes from iPXE itself (User Class or Option 175)
dhcp-userclass=set:ipxe,iPXE
dhcp-match=set:ipxe,175

# Detect Client Architecture (BIOS vs UEFI) for the initial boot
dhcp-match=set:efi-x86_64,option:client-arch,7
dhcp-match=set:efi-x86_64,option:client-arch,9
dhcp-match=set:bios,option:client-arch,0

# --- PXE Menu Services (Option 43) ---
# Required for correct ProxyDHCP operation with many UEFI clients.
pxe-service=tag:!ipxe,x86PC, "Boot from Network (BIOS)", undionly.kpxe
pxe-service=tag:!ipxe,BC_EFI, "Boot from Network (UEFI)", ipxe.efi
pxe-service=tag:!ipxe,X86-64_EFI, "Boot from Network (UEFI)", ipxe.efi

# --- Boot Directives ---
# Syntax: dhcp-boot=<filename>,<servername>,<serverip>
# We Explicitly set <serverip> to ensure the client contacts US.

# 1. If Client is already iPXE -> Send the script (via TFTP)
dhcp-boot=tag:ipxe,boot.ipxe,,$MY_IP

# 2. If Client is NOT iPXE -> Chainload the appropriate binary
dhcp-boot=tag:!ipxe,tag:efi-x86_64,ipxe.efi,,$MY_IP
dhcp-boot=tag:!ipxe,tag:bios,undionly.kpxe,,$MY_IP

# 3. Fallback
dhcp-boot=tag:!ipxe,undionly.kpxe,,$MY_IP

# --- TFTP Server ---
enable-tftp
tftp-root=$WorkDir/tftp
EOF

fi

# 5. Start Services
# -----------------
echo "[-] Starting HTTP server (Port 8000)..."
cd http
pkill -f "python3 -m http.server 8000" || true
python3 -m http.server 8000 &
HTTP_PID=$!
cd ..

cleanup() {
    echo "[-] Stopping HTTP server..."
    kill $HTTP_PID 2>/dev/null || true
}
trap cleanup EXIT

echo "[-] Starting dnsmasq (ProxyDHCP + TFTP)..."
echo "    Log: dnsmasq.conf generated."
echo "    Press CTRL+C to shutdown."

# Run dnsmasq in foreground
sudo dnsmasq -C dnsmasq.conf -d
