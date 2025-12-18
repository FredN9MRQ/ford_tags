#!/bin/bash

# Gaming PC Setup Script for Voice Assistant AI Hub
# Installs Docker, NVIDIA Container Toolkit, and starts AI services

set -e

echo "======================================"
echo "Voice Assistant Gaming PC Setup"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should NOT be run as root${NC}"
   echo "Run it as your regular user. It will ask for sudo when needed."
   exit 1
fi

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
else
    echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}Detected OS: $OS${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Docker (Linux)
install_docker_linux() {
    if command_exists docker; then
        echo -e "${GREEN}Docker already installed${NC}"
    else
        echo -e "${YELLOW}Installing Docker...${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        echo -e "${GREEN}Docker installed. You may need to log out and back in.${NC}"
    fi
}

# Install NVIDIA Container Toolkit (Linux)
install_nvidia_toolkit_linux() {
    echo -e "${YELLOW}Installing NVIDIA Container Toolkit...${NC}"

    # Add NVIDIA Container Toolkit repository
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker

    echo -e "${GREEN}NVIDIA Container Toolkit installed${NC}"
}

# Test NVIDIA GPU access
test_nvidia_gpu() {
    echo -e "${YELLOW}Testing NVIDIA GPU access...${NC}"
    if docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi; then
        echo -e "${GREEN}GPU access working!${NC}"
        return 0
    else
        echo -e "${RED}GPU access test failed${NC}"
        return 1
    fi
}

# Main installation
if [[ "$OS" == "linux" ]]; then
    echo "Starting Linux installation..."

    # Update system
    sudo apt-get update

    # Install Docker
    install_docker_linux

    # Install Docker Compose
    if ! command_exists docker-compose; then
        echo -e "${YELLOW}Installing Docker Compose...${NC}"
        sudo apt-get install -y docker-compose-plugin
    fi

    # Install NVIDIA Container Toolkit
    install_nvidia_toolkit_linux

    # Test GPU
    test_nvidia_gpu

elif [[ "$OS" == "windows" ]]; then
    echo -e "${YELLOW}Windows Setup Instructions:${NC}"
    echo ""
    echo "1. Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    echo "2. Install WSL2: wsl --install"
    echo "3. Enable WSL2 integration in Docker Desktop settings"
    echo "4. Install NVIDIA drivers for WSL2"
    echo "5. Restart and run: docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi"
    echo ""
    echo "Then run this script again, or manually run: docker-compose up -d"
    exit 0
fi

echo ""
echo "======================================"
echo "Starting AI Services"
echo "======================================"
echo ""

# Create config directory
mkdir -p config/custom-wakewords

# Start services
echo -e "${YELLOW}Starting Docker containers...${NC}"
docker-compose up -d

echo ""
echo -e "${GREEN}Waiting for services to start...${NC}"
sleep 10

# Check service status
echo ""
echo "Service Status:"
docker-compose ps

echo ""
echo "======================================"
echo "Downloading AI Models"
echo "======================================"
echo ""

# Download Ollama models
echo -e "${YELLOW}Downloading Ollama models (this may take a while)...${NC}"
echo "Downloading Llama 3.1 8B..."
docker exec ollama ollama pull llama3.1:8b

echo "Downloading Phi-3 Mini (faster responses)..."
docker exec ollama ollama pull phi3:mini

echo ""
echo -e "${GREEN}Setup Complete!${NC}"
echo ""
echo "======================================"
echo "Service URLs:"
echo "======================================"
echo "Ollama API: http://localhost:11434"
echo "Ollama Web UI: http://localhost:8080"
echo "Whisper STT: http://localhost:10300"
echo "Piper TTS: http://localhost:10200"
echo "OpenWakeWord: http://localhost:10400"
echo ""
echo "======================================"
echo "Next Steps:"
echo "======================================"
echo "1. Configure Home Assistant (see ../home-assistant-config/)"
echo "2. Set up Surface Go satellite (see ../surface-go-setup/)"
echo "3. Test voice commands through Home Assistant"
echo ""
echo -e "${YELLOW}Note: Find your PC's IP address with: ip addr show (Linux) or ipconfig (Windows)${NC}"
echo "You'll need this IP for Home Assistant and Surface Go configuration."
echo ""
