# 3D Printing - Shared Orca Slicer Setup

This document describes the setup for sharing Orca Slicer profiles across multiple computers in the homelab, while keeping installations local for best performance.

## Overview

**Goal**: Family members can use Orca Slicer on their own computers with shared profiles for the AD5M printer, with files stored on OMV.

**Approach**:
- Local Orca Slicer installations on each computer (best performance)
- Shared profiles stored on OMV NFS/SMB share
- Shared STL library and gcode output folder on OMV

## OMV Shared Folder Structure

Create the following structure on your OMV storage:

```
/srv/3DPrinting/
├── profiles/           # Shared Orca Slicer profiles
│   ├── filament/      # Filament profiles
│   ├── print/         # Print profiles (layer heights, speeds, etc.)
│   ├── printer/       # Printer profiles (AD5M config)
│   └── process/       # Process profiles
├── models/            # STL files library
│   ├── functional/
│   ├── decorative/
│   └── repairs/
├── gcode/             # Sliced output ready to print
│   ├── queue/         # Ready to print
│   └── archive/       # Completed prints
└── projects/          # Work-in-progress projects
```

## OMV Setup Steps

### 1. Create Shared Folder on OMV

SSH into your OMV server (pve-storage or wherever OMV is running):

```bash
# Create the directory structure
sudo mkdir -p /srv/3DPrinting/{profiles/{filament,print,printer,process},models/{functional,decorative,repairs},gcode/{queue,archive},projects}

# Set permissions (adjust user/group as needed)
sudo chown -R fred:users /srv/3DPrinting
sudo chmod -R 775 /srv/3DPrinting
```

### 2. Create NFS Share in OMV

Via OMV web interface:
1. Storage → Shared Folders → Create
   - Name: `3DPrinting`
   - Device: Your storage device
   - Path: `/3DPrinting/`
   - Permissions: fred (R/W), users (R/W)

2. Services → NFS → Shares → Create
   - Shared folder: `3DPrinting`
   - Client: `10.0.10.0/24` (adjust to your network)
   - Privilege: Read/Write
   - Extra options: `rw,sync,no_subtree_check,no_root_squash`

### 3. Mount on Client Computers

Add to `/etc/fstab` on each client computer:

```bash
# Replace <OMV-IP> with your OMV server IP
<OMV-IP>:/export/3DPrinting /mnt/3DPrinting nfs defaults,user,auto,noatime 0 0
```

Mount the share:
```bash
sudo mkdir -p /mnt/3DPrinting
sudo mount /mnt/3DPrinting
```

Or use SMB/CIFS if preferred:
```bash
# Add to /etc/fstab
//<OMV-IP>/3DPrinting /mnt/3DPrinting cifs credentials=/home/fred/.smbcredentials,uid=1000,gid=1000 0 0
```

## Orca Slicer Installation

### On Ubuntu/Debian (including this computer)

1. Download the latest AppImage from GitHub:
```bash
cd ~/Downloads
wget https://github.com/SoftFever/OrcaSlicer/releases/latest/download/OrcaSlicer_Linux_V2.2.0.AppImage
chmod +x OrcaSlicer_Linux_*.AppImage
```

2. Move to a permanent location:
```bash
sudo mkdir -p /opt/OrcaSlicer
sudo mv OrcaSlicer_Linux_*.AppImage /opt/OrcaSlicer/orca-slicer.AppImage
```

3. Create desktop entry:
```bash
cat > ~/.local/share/applications/orca-slicer.desktop <<EOF
[Desktop Entry]
Name=Orca Slicer
Comment=3D Printer Slicer
Exec=/opt/OrcaSlicer/orca-slicer.AppImage
Icon=orca-slicer
Terminal=false
Type=Application
Categories=Graphics;3DGraphics;
EOF
```

4. Launch Orca Slicer:
```bash
/opt/OrcaSlicer/orca-slicer.AppImage
```

### On Windows

1. Download installer from: https://github.com/SoftFever/OrcaSlicer/releases/latest
2. Run the installer
3. Default install location: `C:\Program Files\OrcaSlicer\`

### On macOS

1. Download DMG from: https://github.com/SoftFever/OrcaSlicer/releases/latest
2. Drag OrcaSlicer to Applications folder

## Profile Sync Setup

### Initial Profile Export (from homelab-command computer)

Once you have Orca Slicer installed with your AD5M profiles configured:

```bash
# Export profiles to shared location
cd ~/.config/OrcaSlicer  # or check actual config location
cp -r user/* /mnt/3DPrinting/profiles/
```

### Profile Sync Script

Create `~/.local/bin/sync-orca-profiles.sh`:

```bash
#!/bin/bash
# Sync Orca Slicer profiles with shared network storage

ORCA_CONFIG="$HOME/.config/OrcaSlicer/user"
SHARED_PROFILES="/mnt/3DPrinting/profiles"

case "$1" in
    push)
        echo "Pushing local profiles to shared storage..."
        rsync -av --delete "$ORCA_CONFIG/" "$SHARED_PROFILES/"
        echo "✓ Profiles pushed"
        ;;
    pull)
        echo "Pulling profiles from shared storage..."
        rsync -av --delete "$SHARED_PROFILES/" "$ORCA_CONFIG/"
        echo "✓ Profiles pulled"
        ;;
    *)
        echo "Usage: sync-orca-profiles.sh {push|pull}"
        echo "  push - Upload your local profiles to shared storage"
        echo "  pull - Download shared profiles to your local config"
        exit 1
        ;;
esac
```

Make it executable:
```bash
chmod +x ~/.local/bin/sync-orca-profiles.sh
```

### Profile Management Workflow

**When you update profiles** (any computer):
```bash
sync-orca-profiles.sh push
```

**When starting on a new computer** or to get latest profiles:
```bash
sync-orca-profiles.sh pull
```

**Tip**: Add to your shell aliases:
```bash
alias orca-push='sync-orca-profiles.sh push'
alias orca-pull='sync-orca-profiles.sh pull'
```

## Orca Slicer Configuration

### First Launch Setup

1. Launch Orca Slicer
2. Skip the configuration wizard (we'll import profiles)
3. Pull shared profiles: `sync-orca-profiles.sh pull`
4. Restart Orca Slicer

### Configure Default Paths

In Orca Slicer preferences:
- **Default output directory**: `/mnt/3DPrinting/gcode/queue/`
- **STL search path**: `/mnt/3DPrinting/models/`

### Printer Profile - AD5M

If starting fresh, configure:
- Printer: Generic Ender 3 or Custom
- Bed size: 220 x 220 mm (adjust for your AD5M)
- Build height: 250 mm (adjust for your AD5M)
- Nozzle diameter: 0.4 mm (or your actual nozzle)

## Workflow for Family Members

### Printing a Model

1. **Find or add STL file**:
   - Browse `/mnt/3DPrinting/models/`
   - Or add new file to the models folder

2. **Slice in Orca Slicer**:
   - Open STL from models folder
   - Select printer profile: "AD5M"
   - Select filament profile (PLA, PETG, etc.)
   - Select print profile (quality level)
   - Slice and export to `/mnt/3DPrinting/gcode/queue/`

3. **Send to printer**:
   - Copy gcode to SD card, or
   - Use OctoPrint/Mainsail if you set one up (optional)

4. **After printing**:
   - Move gcode from `queue/` to `archive/`

### Sharing New Profiles

If someone creates a great new profile:
```bash
sync-orca-profiles.sh push
# Then others can: sync-orca-profiles.sh pull
```

## Advantages of This Setup

✅ **Performance**: Native app speed, no web lag
✅ **No Conflicts**: Each user has their own instance
✅ **Shared Knowledge**: Everyone uses the same tested profiles
✅ **Centralized Storage**: All files in one place, backed up by OMV
✅ **Easy Updates**: Sync profiles when they improve
✅ **Offline Work**: Can slice without network (if files are local)

## Optional Enhancements

### OctoPrint Integration (Optional)

If you want to skip SD cards and print over network:

1. Install OctoPrint on a Raspberry Pi or in a container
2. Connect to AD5M via USB
3. Configure Orca Slicer to upload directly to OctoPrint
4. Everyone can queue prints from anywhere

### Automatic Profile Sync (Optional)

Add to crontab to auto-pull profiles daily:
```bash
# Add to crontab -e
0 9 * * * /home/fred/.local/bin/sync-orca-profiles.sh pull
```

### Version Control for Profiles (Advanced)

Initialize git in the profiles folder to track changes:
```bash
cd /mnt/3DPrinting/profiles
git init
git add .
git commit -m "Initial profiles"
```

## Troubleshooting

### Profiles Not Showing Up

1. Check if share is mounted: `df -h | grep 3DPrinting`
2. Check Orca Slicer config location: May be `~/.config/OrcaSlicer` or `~/.local/share/OrcaSlicer`
3. Run `sync-orca-profiles.sh pull` manually

### Permission Issues

```bash
# Fix permissions on shared folder
sudo chown -R $USER:users /mnt/3DPrinting
sudo chmod -R 775 /mnt/3DPrinting
```

### Different Orca Slicer Versions

If different computers have different Orca Slicer versions, profiles may have compatibility issues. Keep all installations on the same major version.

## Next Steps

- [ ] Set up OMV 3DPrinting share
- [ ] Mount share on homelab-command computer
- [ ] Install Orca Slicer on homelab-command
- [ ] Configure AD5M printer profile
- [ ] Test print and tune profiles
- [ ] Export profiles to shared location
- [ ] Install Orca Slicer on family computers
- [ ] Test profile sync workflow
- [ ] (Optional) Set up OctoPrint for network printing

## References

- Orca Slicer GitHub: https://github.com/SoftFever/OrcaSlicer
- Orca Slicer Documentation: https://github.com/SoftFever/OrcaSlicer/wiki
