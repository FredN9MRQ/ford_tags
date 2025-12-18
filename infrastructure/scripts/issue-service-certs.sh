#!/bin/bash
# Issue HTTPS certificates for homelab services
# Run this on main-pve after CA is set up

set -e

CA_CONTAINER_ID=115
CERT_DIR="/tmp/certs"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Issuing Service Certificates${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Create certificate output directory
mkdir -p $CERT_DIR

# Services to issue certificates for
declare -A SERVICES=(
    ["bob.nianticbooks.home"]="10.0.10.24"
    ["ad5m.nianticbooks.home"]="10.0.10.30"
    ["dockge.nianticbooks.home"]="10.0.10.27"
    ["freddesk.nianticbooks.home"]="10.0.10.3"
    ["pve-router.nianticbooks.home"]="10.0.10.2"
    ["omv.nianticbooks.home"]="10.0.10.5"
)

# Issue certificate for each service
for domain in "${!SERVICES[@]}"; do
    ip="${SERVICES[$domain]}"

    echo -e "${YELLOW}Issuing certificate for: $domain (${ip})${NC}"

    # Generate certificate inside CA container
    pct exec $CA_CONTAINER_ID -- bash <<EOFC
set -e
cd /tmp

# Issue certificate
step certificate create "$domain" \
    "${domain}.crt" "${domain}.key" \
    --profile leaf \
    --not-after 8760h \
    --ca /etc/step-ca/certs/intermediate_ca.crt \
    --ca-key /etc/step-ca/secrets/intermediate_ca_key \
    --no-password \
    --insecure \
    --bundle

echo "✓ Certificate generated for $domain"
EOFC

    # Pull certificates from container
    pct pull $CA_CONTAINER_ID "/tmp/${domain}.crt" "${CERT_DIR}/${domain}.crt"
    pct pull $CA_CONTAINER_ID "/tmp/${domain}.key" "${CERT_DIR}/${domain}.key"

    echo -e "${GREEN}✓ ${domain}.crt and ${domain}.key saved to ${CERT_DIR}/${NC}"
    echo ""
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Certificate Generation Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Certificates saved to: $CERT_DIR"
echo ""
echo "Next steps:"
echo "  1. Copy certificates to each service"
echo "  2. Configure services to use HTTPS"
echo "  3. Restart services"
echo ""
echo "Certificate files:"
ls -lh $CERT_DIR/
echo ""
