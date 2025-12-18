# 3D Printing Setup - Quick Start Guide

Quick reference for setting up Orca Slicer with shared profiles on your homelab.

## First Time Setup (Run these commands)

### 1. Mount the 3DPrinting Share

```bash
# Mount the OMV share
sudo mount-3dprinting.sh

# OR set up automatic mounting on boot
sudo setup-3dprinting-automount.sh
sudo mount /mnt/3DPrinting
```

Verify it worked:
```bash
ls -la /mnt/3DPrinting/3DPrinting/
```

You should see: `profiles/`, `models/`, `gcode/`, `projects/`

### 2. Install Orca Slicer

```bash
# Install from the downloaded AppImage
sudo install-orca-slicer.sh
```

### 3. Launch Orca Slicer

```bash
/opt/OrcaSlicer/orca-slicer.AppImage
```

Or search for "Orca Slicer" in your application menu.

## Daily Usage

### Slicing a Model

1. Open Orca Slicer
2. File → Import → Select STL from `/mnt/3DPrinting/3DPrinting/models/`
3. Select profiles:
   - Printer: AD5M
   - Filament: PLA/PETG/etc
   - Print: Quality level
4. Slice
5. Export gcode to `/mnt/3DPrinting/3DPrinting/gcode/queue/`
6. Transfer to printer and print!

### Syncing Profiles

**Get latest shared profiles:**
```bash
sync-orca-profiles.sh pull
```

**Share your updated profiles:**
```bash
sync-orca-profiles.sh push
```

**Check sync status:**
```bash
sync-orca-profiles.sh status
```

## File Locations

### On OMV (10.0.10.5)
```
/srv/dev-disk-by-uuid-1c893fab-9943-43df-8e24-3c9190869955/data/3DPrinting/
├── profiles/      # Shared Orca Slicer profiles
├── models/        # STL files
├── gcode/         # Sliced gcode files
└── projects/      # Work in progress
```

### On This Computer
```
/mnt/3DPrinting/3DPrinting/  # Mounted share (same as above)
~/.config/OrcaSlicer/user/   # Local Orca Slicer profiles
```

## Troubleshooting

### Share not mounted?
```bash
# Check if mounted
mount | grep 3DPrinting

# If not mounted
sudo mount-3dprinting.sh
```

### Can't find profiles in Orca Slicer?
```bash
# Pull profiles from shared storage
sync-orca-profiles.sh pull

# Restart Orca Slicer
```

### OMV server not accessible?
```bash
# Test connection
ping 10.0.10.5

# Check if SMB is running on OMV
ssh 10.0.10.5 "systemctl status smbd"
```

## Helper Scripts

All scripts are in `~/.local/bin/`:

| Script | Purpose |
|--------|---------|
| `mount-3dprinting.sh` | Mount the 3DPrinting share (requires sudo) |
| `setup-3dprinting-automount.sh` | Configure automatic mounting on boot |
| `install-orca-slicer.sh` | Install Orca Slicer from AppImage |
| `sync-orca-profiles.sh pull` | Download shared profiles |
| `sync-orca-profiles.sh push` | Upload your profiles to share |
| `sync-orca-profiles.sh status` | Check sync configuration |

## Next Steps

1. ✅ Mount share: `sudo mount-3dprinting.sh`
2. ✅ Install Orca Slicer: `sudo install-orca-slicer.sh`
3. 🔲 Launch Orca Slicer and configure AD5M printer profile
4. 🔲 Test slice a model
5. 🔲 Push your AD5M profiles: `sync-orca-profiles.sh push`
6. 🔲 Install Orca Slicer on other family computers
7. 🔲 On those computers: mount share, install Orca Slicer, pull profiles

## Family Members: Getting Started

If you're a family member setting up Orca Slicer on your computer:

1. **Mount the network share** (ask Fred for help with this part)
2. **Install Orca Slicer** - Download from https://github.com/SoftFever/OrcaSlicer/releases/latest
3. **Get the shared profiles**:
   ```bash
   sync-orca-profiles.sh pull
   ```
4. **Start slicing!** All the AD5M profiles are ready to use

## Documentation

For complete setup details, see: [3D-PRINTING-SETUP.md](3D-PRINTING-SETUP.md)
