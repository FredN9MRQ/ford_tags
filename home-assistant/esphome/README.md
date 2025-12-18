# ESPHome Devices

This directory contains ESPHome configurations for all ESP32/ESP8266 devices in the smart home system.

## Devices

### garage-controller.yaml
- **Hardware:** ESP32-WROOM-32E with 8-channel relay board
- **Relays:** SRD-05VDC-SL-C (10A @ 250VAC)
- **Current Functions:**
  - North & South garage door control
  - Bay lighting (North, South, Workbench)
  - Temperature/humidity monitoring (AHT20+BMP280)
- **Planned Functions:**
  - Furnace control integration (relays 6-8)
  - Multi-zone temperature monitoring
  - Exhaust fan safety monitoring

## Shared Configuration

Common sensors, binary sensors, and utility configurations can be placed in a `common/` subdirectory and included via:

```yaml
<<: !include common/wifi.yaml
```

## Secrets Management

Create a `secrets.yaml` file (gitignored) with:

```yaml
wifi_ssid: "your-ssid"
wifi_password: "your-password"
# Add other secrets as needed
```

## Deployment

Devices can be flashed via:
- USB (initial setup)
- OTA updates through Home Assistant ESPHome integration
- ESPHome CLI: `esphome run device-name.yaml`

## Documentation

- **FURNACE-SPECS.md** - Complete furnace specifications, control board details, and wiring information
- `/docs/FURNACE-PROJECT.md` - Furnace control project overview, implementation plan, and safety considerations
