# Furnace Controller Specifications

## Overview
This document contains detailed specifications for the furnace control system, including original equipment specifications, replacement options, and circuit/wiring information.

## Furnace Unit

### Amana GCCA090BX40
- **Manufacturer**: Amana
- **Model**: GCCA090BX40
- **Serial Number**: 0210126144
- **Output Capacity**: 87,500 BTU/hr
- **Type**: Gas forced air furnace
- **Ignition**: Hot surface ignitor
- **Stages**: Single-stage heating

## Current Equipment

### Control Board
- **Model**: White-Rodgers 50A-LT735
- **Type**: Single-stage hot surface ignitor integrated furnace control
- **Status**: Currently installed and operational
- **Photos**: IMG_6629.jpg, IMG_6635.jpg, IMG_6638.jpg

### Gas Valve
- **Model**: 36F22-243 E1
- **Voltage**: 24V 60Hz
- **Current**: 0.35 AMP
- **Maximum Pressure**: 1/2 PSI
- **Regulated Pressure**: 3.5" W.C.
- **Certification**: CSA certified
- **Photo**: IMG_6644.jpg

### Installation Requirements
- Must be installed in accordance with manufacturer instructions and local codes
- **Codes**:
  - National Fuel Gas Code, ANSI Z223.1
  - CAN/CGA-B149 installation codes
- **Clearances**: See IMG_6630.jpg for minimum clearance to combustible materials
- **Position**: Horizontal/Alcove installation (per clearance table)

## Recommended Replacement Board

### White-Rodgers 50A55-743
- **Type**: Single-Stage Hot-Surface Ignitor Integrated Furnace Control Kit
- **Source**: https://www.supplyhouse.com/White-Rodgers-50A55-743-Single-Stage-Hot-Surface-Ignitor-Integrated-Furnace-Control-Kit
- **Recommended by**: HVAC technician
- **Compatibility**: Designed as replacement for older White-Rodgers control boards
- **Features**:
  - Single-stage operation
  - Hot surface ignition
  - Integrated furnace control
  - Direct replacement kit

### Replacement Considerations
- Verify compatibility with current gas valve (36F22-243 E1)
- Ensure transformer output matches voltage requirements (24V)
- Confirm wiring terminal layout matches existing configuration
- Review installation manual before purchase

## Wiring and Circuit Information

### Control Board Terminals (from photos)
The White-Rodgers 50A-LT735 board shows the following terminal connections:

**Power Input:**
- Transformer powered (24V AC)
- See transformer specifications below

**Control Connections:**
- Thermostat connections (R, W, G, Y terminals visible)
- Safety switch connections
- Limit switch connections
- Gas valve connection (24V output)
- Blower motor control

### Transformer Specifications
- **Photo**: IMG_6639.jpg, IMG_6640.jpg
- **Primary**: 120V AC
- **Secondary**: 24V AC
- **Label visible on unit** (specific amp rating visible in photos)

### Circuit Path Notes
- **Photos**: IMG_6629.jpg, IMG_6635.jpg, IMG_6636.jpg show wiring layout
- Purple wire connections visible to thermostat circuit
- Blue wire connections to various controls
- Ground wire (green/yellow) visible
- Multiple safety interlocks in series

### Safety Devices Visible
1. **Limit switches** - Temperature safety cutoffs
2. **Pressure switch** - Vent pressure verification
3. **Roll-out switch** - Flame roll-out protection
4. **Gas valve safety shutoff** - Controlled by board

## Photo Reference Index

| Photo | Content | Key Information |
|-------|---------|-----------------|
| IMG_6629.jpg | Control board front view | Board model, wiring terminals, connections |
| IMG_6630.jpg | Installation clearances | ANSI/CAN codes, clearance requirements |
| IMG_6634.jpg | Furnace nameplate | Model, BTU, gas specs (sideways) |
| IMG_6635.jpg | Control board wiring | Terminal layout, wire routing |
| IMG_6636.jpg | Control board detail | Circuit details, resistors visible |
| IMG_6638.jpg | Control board front | Overall wiring view |
| IMG_6639.jpg | Transformer label | Transformer specifications |
| IMG_6640.jpg | Transformer | Better view of transformer label |
| IMG_6644.jpg | Gas valve | Gas valve model and specifications |

## ESPHome Integration Notes

### Potential Monitoring Points
1. **Thermostat call (W terminal)** - Detect heat demand
2. **Blower status (G terminal)** - Monitor blower operation
3. **Flame sensor** - Verify ignition (if accessible)
4. **Limit switches** - Temperature monitoring

### Control Considerations
- **WARNING**: Direct control of furnace requires proper safety interlocks
- Consider monitoring-only approach initially
- Gas furnace control requires certified installation for safety/insurance
- ESPHome can safely monitor thermostat signals without interfering with operation

### Recommended Approach
1. **Monitor only** - Read thermostat W/G/Y signals to know furnace state
2. **No direct control** - Leave existing thermostat control in place
3. **Temperature sensors** - Add external temp sensors via ESPHome
4. **Smart scheduling** - Use Home Assistant automations with existing thermostat

## Maintenance Notes

### Regular Inspection Items
- Control board connections (look for corrosion)
- Transformer output voltage (should be steady 24V AC)
- Gas valve operation (should open/close cleanly)
- Flame sensor (clean annually)
- Air filter (check monthly)

### Warning Signs
- Board LED error codes (document specific patterns if seen)
- Clicking or buzzing from gas valve
- Delayed ignition
- Short cycling
- Transformer overheating

## Additional Resources

### Manuals Needed
- [ ] Amana GCCA090BX40 service manual
- [ ] White-Rodgers 50A-LT735 installation manual
- [ ] White-Rodgers 50A55-743 replacement manual (for future reference)
- [ ] Gas valve 36F22-243 specifications

### Future Documentation
- [x] Extract complete furnace model number from nameplate (IMG_6634.jpg) - **GCCA090BX40**
- [x] Document exact BTU/hr rating - **87,500 BTU/hr**
- [x] Record furnace serial number - **0210126144**
- [ ] Document blower motor specifications
- [ ] Map complete wiring diagram
- [ ] Obtain Amana GCCA090BX40 service manual

## Safety Disclaimer

**IMPORTANT**:
- Gas furnace work requires qualified HVAC technician
- Incorrect wiring can cause gas leaks, fire, or carbon monoxide hazards
- Always turn off power and gas before any work
- Local codes may require permits for control system modifications
- Some changes may void warranty or affect insurance coverage

---

*Document created: 2025-11-28*
*Photos location: C:\Users\Fred\AI\claude\infrastructure\esphome\Pictures*
