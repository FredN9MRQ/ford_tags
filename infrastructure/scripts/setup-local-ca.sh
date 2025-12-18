#!/bin/bash
# Setup Local Certificate Authority using step-ca
# Run this script on main-pve (10.0.10.3)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Local CA Setup for Homelab${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Configuration
CA_CONTAINER_ID=115
CA_HOSTNAME="ca-server"
CA_IP="10.0.10.15"
CA_DOMAIN="ca.nianticbooks.home"
CA_NAME="Homelab Internal CA"
GATEWAY="10.0.10.1"

# Check if running on Proxmox
if [ ! -f /etc/pve/.version ]; then
    echo -e "${RED}Error: This script must run on a Proxmox host${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Creating LXC Container for CA${NC}"
echo "Container ID: $CA_CONTAINER_ID"
echo "IP Address: $CA_IP"
echo ""

# Check if container already exists
if pct status $CA_CONTAINER_ID &>/dev/null; then
    echo -e "${YELLOW}Container $CA_CONTAINER_ID already exists${NC}"
    read -p "Destroy and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pct stop $CA_CONTAINER_ID || true
        pct destroy $CA_CONTAINER_ID
    else
        echo "Using existing container"
        pct start $CA_CONTAINER_ID || true
        sleep 5
        CA_EXISTS=true
    fi
fi

if [ "$CA_EXISTS" != "true" ]; then
    # Download Ubuntu template if needed
    if [ ! -f /var/lib/vz/template/cache/ubuntu-22.04-standard_22.04-1_amd64.tar.zst ]; then
        echo "Downloading Ubuntu 22.04 template..."
        pveam update
        pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
    fi

    # Create container
    echo "Creating container..."
    pct create $CA_CONTAINER_ID \
        local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
        --hostname $CA_HOSTNAME \
        --cores 1 \
        --memory 512 \
        --swap 512 \
        --storage local-lvm \
        --rootfs 8 \
        --net0 name=eth0,bridge=vmbr0,ip=${CA_IP}/24,gw=$GATEWAY \
        --unprivileged 1 \
        --features nesting=1 \
        --onboot 1 \
        --password

    # Start container
    echo "Starting container..."
    pct start $CA_CONTAINER_ID
    sleep 10
fi

echo -e "${GREEN}✓ Container created and started${NC}"
echo ""

echo -e "${YELLOW}Step 2: Installing step-ca${NC}"

# Install step-ca and step-cli
pct exec $CA_CONTAINER_ID -- bash <<'EOFC'
set -e

# Update and install dependencies
apt update
apt install -y wget curl

# Download step binaries
cd /tmp
wget -q https://dl.smallstep.com/gh-release/cli/gh-release-header/v0.25.0/step-cli_0.25.0_amd64.deb
wget -q https://dl.smallstep.com/gh-release/certificates/gh-release-header/v0.25.0/step-ca_0.25.0_amd64.deb

# Install
dpkg -i step-cli_0.25.0_amd64.deb step-ca_0.25.0_amd64.deb

# Verify
step version
step-ca version

echo "✓ step-ca installed"
EOFC

echo -e "${GREEN}✓ step-ca installed${NC}"
echo ""

echo -e "${YELLOW}Step 3: Initializing CA${NC}"
echo ""
echo "You will be prompted for:"
echo "  1. CA password (save this in your password manager!)"
echo "  2. Provisioner password (can be the same)"
echo ""
read -p "Press Enter to continue..."

# Initialize CA
pct exec $CA_CONTAINER_ID -- bash <<EOFC
set -e

# Create step user
if ! id -u step &>/dev/null; then
    useradd -r -s /bin/bash -m -d /etc/step-ca step
fi

# Initialize CA as step user
sudo -u step bash <<'EOFSTEP'
if [ ! -f /etc/step-ca/config/ca.json ]; then
    step ca init \
        --name="$CA_NAME" \
        --dns="$CA_DOMAIN" \
        --address=":443" \
        --provisioner="admin@nianticbooks.home" \
        --deployment-type=standalone
else
    echo "CA already initialized"
fi
EOFSTEP

echo "✓ CA initialized"
EOFC

echo -e "${GREEN}✓ CA initialized${NC}"
echo ""

echo -e "${YELLOW}Step 4: Configuring systemd service${NC}"

# Create systemd service
pct exec $CA_CONTAINER_ID -- bash <<'EOFC'
cat > /etc/systemd/system/step-ca.service <<'EOF'
[Unit]
Description=step-ca Certificate Authority
After=network.target

[Service]
Type=simple
User=step
Group=step
WorkingDirectory=/etc/step-ca
ExecStart=/usr/bin/step-ca /etc/step-ca/config/ca.json --password-file=/etc/step-ca/password.txt
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Prompt for password to store
echo "Enter CA password to store in password file:"
read -s CA_PASS
echo "$CA_PASS" > /etc/step-ca/password.txt
chown step:step /etc/step-ca/password.txt
chmod 600 /etc/step-ca/password.txt

# Enable and start service
systemctl daemon-reload
systemctl enable step-ca
systemctl start step-ca
sleep 3
systemctl status step-ca --no-pager

echo "✓ systemd service configured and started"
EOFC

echo -e "${GREEN}✓ step-ca service running${NC}"
echo ""

echo -e "${YELLOW}Step 5: Extracting root certificate${NC}"

# Copy root CA certificate to host
pct pull $CA_CONTAINER_ID /etc/step-ca/certs/root_ca.crt /tmp/homelab-root-ca.crt

echo -e "${GREEN}✓ Root CA certificate saved to: /tmp/homelab-root-ca.crt${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}CA Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Distribute /tmp/homelab-root-ca.crt to all devices"
echo "  2. Issue certificates for services"
echo "  3. Configure services to use HTTPS"
echo ""
echo "Root CA certificate location: /tmp/homelab-root-ca.crt"
echo "CA server: https://$CA_DOMAIN"
echo "CA container IP: $CA_IP"
echo ""
