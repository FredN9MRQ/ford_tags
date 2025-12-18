#!/bin/bash

# Surface Go Voice Satellite Setup (Linux)
# Installs Wyoming Satellite for voice interaction

set -e

echo "======================================"
echo "Surface Go Voice Satellite Setup"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should NOT be run as root${NC}"
   echo "Run it as your regular user. It will ask for sudo when needed."
   exit 1
fi

# Check Python version
echo -e "${YELLOW}Checking Python installation...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python3 not found!${NC}"
    echo "Installing Python..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo -e "${GREEN}Python version: $PYTHON_VERSION${NC}"

# Check if version is 3.10+
if ! python3 -c 'import sys; exit(0 if sys.version_info >= (3, 10) else 1)'; then
    echo -e "${RED}Python 3.10+ required, found $PYTHON_VERSION${NC}"
    exit 1
fi

echo ""

# Install audio dependencies
echo -e "${YELLOW}Installing audio dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y \
    portaudio19-dev \
    python3-pyaudio \
    alsa-utils \
    pulseaudio \
    libopenblas-dev

echo ""

# Get configuration
echo "======================================"
echo "Configuration"
echo "======================================"
echo ""

read -p "Enter your Gaming PC IP address (e.g., 192.168.1.100): " GAMING_PC_IP
read -p "Enter your Home Assistant IP address (e.g., 192.168.1.50): " HA_IP

echo ""
echo -e "${GREEN}Configuration:${NC}"
echo -e "  Gaming PC IP: ${CYAN}$GAMING_PC_IP${NC}"
echo -e "  Home Assistant IP: ${CYAN}$HA_IP${NC}"
echo ""

read -p "Is this correct? (Y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled"
    exit 0
fi

echo ""
echo "======================================"
echo "Installing Wyoming Satellite"
echo "======================================"
echo ""

# Create installation directory
INSTALL_PATH="$HOME/wyoming-satellite"
echo -e "${YELLOW}Creating installation directory at: $INSTALL_PATH${NC}"
mkdir -p "$INSTALL_PATH"
cd "$INSTALL_PATH"

# Create virtual environment
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
python3 -m venv venv

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source venv/bin/activate

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --upgrade pip wheel

# Install Wyoming satellite
echo -e "${YELLOW}Installing Wyoming Satellite...${NC}"
pip install wyoming-satellite

# Install PyAudio
echo -e "${YELLOW}Installing PyAudio...${NC}"
pip install pyaudio

echo ""
echo "======================================"
echo "Creating Configuration"
echo "======================================"
echo ""

# Create configuration file
cat > config.yaml << EOF
# Wyoming Satellite Configuration

# Microphone settings
microphone:
  device: ""  # Leave empty for default device
  sample_rate: 16000
  channels: 1

# Audio output settings
speaker:
  device: ""  # Leave empty for default device
  sample_rate: 22050

# Wyoming protocol settings
wyoming:
  # STT (Speech-to-Text) - Gaming PC Whisper
  stt:
    uri: "tcp://${GAMING_PC_IP}:10300"

  # TTS (Text-to-Speech) - Gaming PC Piper
  tts:
    uri: "tcp://${GAMING_PC_IP}:10200"

  # Wake word detection - Gaming PC OpenWakeWord
  wake:
    uri: "tcp://${GAMING_PC_IP}:10400"
    names:
      - "ok_nabu"  # Default wake word

# Home Assistant connection
home_assistant:
  url: "http://${HA_IP}:8123"
  token: ""  # Add your long-lived access token here

# Satellite settings
satellite:
  name: "Surface Go"
  area: "office"  # Change to your room/area

# Audio feedback
sounds:
  awake: ""  # Path to sound file when wake word detected
  done: ""   # Path to sound file when processing complete

# Debug settings
debug: false
EOF

echo -e "${GREEN}Configuration file created: $INSTALL_PATH/config.yaml${NC}"

echo ""
echo "======================================"
echo "Testing Audio Devices"
echo "======================================"
echo ""

echo -e "${YELLOW}Available audio input devices:${NC}"
arecord -l

echo ""
echo -e "${YELLOW}Available audio output devices:${NC}"
aplay -l

echo ""
echo "======================================"
echo "Creating Systemd Service"
echo "======================================"
echo ""

# Create systemd service
SYSTEMD_SERVICE="$HOME/.config/systemd/user/wyoming-satellite.service"
mkdir -p "$HOME/.config/systemd/user"

cat > "$SYSTEMD_SERVICE" << EOF
[Unit]
Description=Wyoming Satellite Voice Assistant
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_PATH
ExecStart=$INSTALL_PATH/venv/bin/python -m wyoming_satellite --config $INSTALL_PATH/config.yaml
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

echo -e "${GREEN}Systemd service created${NC}"

# Enable and start service
systemctl --user daemon-reload
systemctl --user enable wyoming-satellite.service

echo ""
echo -e "${GREEN}======================================"
echo "Installation Complete!"
echo "======================================${NC}"
echo ""

echo "======================================"
echo "Next Steps:"
echo "======================================"
echo ""
echo -e "${CYAN}1. Get a Home Assistant Long-Lived Access Token:${NC}"
echo "   - Open Home Assistant: http://$HA_IP:8123"
echo "   - Go to Profile > Security > Long-Lived Access Tokens"
echo "   - Create a token and add it to config.yaml"
echo ""
echo -e "${CYAN}2. Edit the configuration if needed:${NC}"
echo "   nano $INSTALL_PATH/config.yaml"
echo ""
echo -e "${CYAN}3. Start the satellite:${NC}"
echo "   systemctl --user start wyoming-satellite.service"
echo ""
echo -e "${CYAN}4. Check status:${NC}"
echo "   systemctl --user status wyoming-satellite.service"
echo ""
echo -e "${CYAN}5. View logs:${NC}"
echo "   journalctl --user -u wyoming-satellite.service -f"
echo ""
echo -e "${CYAN}6. Test audio (optional):${NC}"
echo "   arecord -d 3 test.wav && aplay test.wav"
echo ""

# Create manual start script
cat > start-satellite.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
python -m wyoming_satellite --config config.yaml
EOF

chmod +x start-satellite.sh
echo -e "${GREEN}Manual start script created: $INSTALL_PATH/start-satellite.sh${NC}"
echo ""
