#!/bin/bash
# Install and trust the homelab root CA certificate
# Run this on each client computer (Linux/Mac)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CA_SERVER="10.0.10.15"
CA_CERT_PATH="/etc/step-ca/certs/root_ca.crt"
LOCAL_CERT_NAME="homelab-root-ca.crt"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installing Homelab Root CA${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Detect OS
if [ "$(uname)" == "Darwin" ]; then
    OS="mac"
elif [ -f /etc/os-release ]; then
    OS="linux"
else
    echo -e "${RED}Unsupported operating system${NC}"
    exit 1
fi

echo "Detected OS: $OS"
echo "Fetching root CA from: $CA_SERVER"
echo ""

# Fetch root CA certificate
echo -e "${YELLOW}Fetching root CA certificate...${NC}"
if command -v scp &> /dev/null; then
    scp "root@${CA_SERVER}:${CA_CERT_PATH}" "/tmp/${LOCAL_CERT_NAME}"
else
    # Fallback: try curl if ssh not available
    curl -k "https://${CA_SERVER}/roots.pem" -o "/tmp/${LOCAL_CERT_NAME}"
fi

if [ ! -f "/tmp/${LOCAL_CERT_NAME}" ]; then
    echo -e "${RED}Failed to fetch root CA certificate${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Root CA certificate downloaded${NC}"
echo ""

# Install based on OS
if [ "$OS" == "linux" ]; then
    echo -e "${YELLOW}Installing on Linux...${NC}"

    # Check distribution
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        sudo cp "/tmp/${LOCAL_CERT_NAME}" "/usr/local/share/ca-certificates/${LOCAL_CERT_NAME}"
        sudo update-ca-certificates
    elif [ -f /etc/redhat-release ]; then
        # RHEL/CentOS/Fedora
        sudo cp "/tmp/${LOCAL_CERT_NAME}" "/etc/pki/ca-trust/source/anchors/${LOCAL_CERT_NAME}"
        sudo update-ca-trust
    else
        echo -e "${RED}Unsupported Linux distribution${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Root CA installed and trusted${NC}"

elif [ "$OS" == "mac" ]; then
    echo -e "${YELLOW}Installing on macOS...${NC}"

    sudo security add-trusted-cert \
        -d -r trustRoot \
        -k /Library/Keychains/System.keychain \
        "/tmp/${LOCAL_CERT_NAME}"

    echo -e "${GREEN}✓ Root CA installed and trusted${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Testing HTTPS connections to homelab services..."
echo ""

# Test services
declare -a SERVICES=(
    "https://bob.nianticbooks.home:8123"
    "https://ad5m.nianticbooks.home"
    "https://freddesk.nianticbooks.home:8006"
)

for service in "${SERVICES[@]}"; do
    echo -n "Testing $service... "
    if curl -s -I -m 5 "$service" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠ (service may not be configured for HTTPS yet)${NC}"
    fi
done

echo ""
echo "Root CA installed successfully!"
echo "You should now be able to access homelab services via HTTPS without warnings."
echo ""
