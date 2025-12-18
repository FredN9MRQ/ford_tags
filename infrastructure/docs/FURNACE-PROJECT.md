# Furnace Control Project

## Overview

Integration of ESP32-based control system for garage furnace with multi-zone temperature monitoring and Home Assistant automation.

## Objectives

- Replace failed furnace control board with ESP32-based solution
- Enable multi-zone monitoring (garage + wife's shed)
- Integrate with Home Assistant for advanced scheduling and automation
- Maintain all safety interlocks and proper HVAC sequencing
- Monitor furnace health and efficiency metrics

## Hardware

### Furnace Unit
- **Manufacturer**: Amana
- **Model**: GCCA090BX40
- **Serial Number**: 0210126144
- **Output**: 87,500 BTU/hr
- **Type**: Single-stage gas forced air with hot surface ignition
- **Control Board**: White-Rodgers 50A-LT735
- **Gas Valve**: 36F22-243 E1 (24V, 0.35A)

### Controller
- **Board:** ESP32-WROOM-32E Development Board with 8-way 5V relay module
- **Location:** Garage
- **Configuration:** `/esphome/garage-controller.yaml`

### Relays
- **Model:** SRD-05VDC-SL-C
- **Rating:** 10A @ 250VAC (resistive), ~5A (inductive)
- **Allocation:**
  - Relays 1-2: Garage doors (in use)
  - Relays 3-5: Lighting (in use)
  - **Relay 6: Furnace control** (reserved)
  - **Relay 7: Available** for furnace (inducer/blower)
  - **Relay 8: Available** for furnace (second zone/aux)

### Temperature Sensors
- **Quantity:** 6x AHT20+BMP280 modules
- **Measurements:** Temperature, Humidity, Air Pressure
- **Planned Locations:**
  1. Main garage area (currently installed)
  2. Wife's shed
  3. Return air temperature
  4. Supply air temperature
  5. Outdoor temperature (for efficiency calculations)
  6. Spare/redundancy

### Furnace Safety Switches
- Exhaust fan proof switch (binary)
- Pressure switch (binary)
- Limit switches (high temperature cutoff)
- Flame sensor (analog or binary)

## Project Status

### ✅ Completed
- ESP32 board configured with ESPHome
- Garage door and lighting control operational
- Initial temperature/humidity monitoring working
- Relay specifications confirmed suitable for HVAC control
- **Documented furnace specifications** (see `/esphome/FURNACE-SPECS.md`)
- **Photographed existing control board wiring** (photos in `/esphome/Pictures/`)
- **Determined furnace component current draws:**
  - Gas valve: 0.35A @ 24V
  - Control board: White-Rodgers 50A-LT735
  - Replacement option identified: White-Rodgers 50A55-743

### 🔄 In Progress
- Planning relay integration strategy
- Designing safety interlock system

### 📋 Pending
- Design control sequence logic
- Implement ESPHome climate component
- Add binary sensor monitoring for safety switches
- Configure multi-zone temperature monitoring
- Set up Home Assistant automations
- Testing and validation

## Technical Considerations

### Relay Strategy

**Option A: Thermostat Emulation (Simple & Safe)**
- Use Relay 6 to close R-W circuit (24VAC call for heat)
- Furnace's internal board handles all sequencing
- ESP32 acts as smart thermostat
- Lowest risk, easiest implementation

**Option B: Full Control (Advanced)**
- Direct control of inducer, gas valve, blower
- Requires understanding complete furnace sequence
- More flexibility but higher complexity
- Consider using salvaged HVAC-rated relays from failed board

**Option C: Hybrid**
- Use ESP32 relays for 24VAC control signals
- Salvage original board's relays for high-current 120VAC loads (blower motor)
- Best of both worlds

### Safety Architecture

**Hardware Interlocks (Non-Negotiable):**
- Limit switches hardwired in series with gas valve
- Rollout switch hardwired
- Manual shutoff switch
- Can operate independently of ESP32

**Software Interlocks:**
- Flame sensor verification before continuing gas flow
- Pressure switch monitoring (exhaust is flowing)
- Minimum/maximum cycle times
- Lockout after failed ignition attempts
- Watchdog timer for ESP32 crashes

**Failure Modes:**
- ESP32 crash → relays open → furnace shuts down safely
- WiFi loss → continue current mode, log alert
- Home Assistant offline → ESP32 operates autonomously
- Power loss → manual bypass available

### Multi-Zone Control

**Current Zones:**
1. Main garage
2. Wife's shed (fed by same furnace)

**Implementation Options:**
- **Temperature averaging:** Heat when either zone below setpoint
- **Weighted priority:** Garage has higher priority
- **Zone dampers:** Add motorized dampers for true zone control (future)
- **Runtime balancing:** Longer cycles favor shed heating

## ESPHome Configuration Plan

### Climate Component
```yaml
climate:
  - platform: thermostat
    name: "Garage Furnace"
    sensor: garage_avg_temp  # Average of multiple sensors
    default_target_temperature_low: 10°C

    heat_action:
      # Safety checks before calling for heat
      - if:
          condition:
            and:
              - binary_sensor.is_on: pressure_switch
              - binary_sensor.is_off: limit_switch_tripped
          then:
            - switch.turn_on: furnace_relay

    idle_action:
      - switch.turn_off: furnace_relay
```

### Binary Sensors (Safety Monitoring)
```yaml
binary_sensor:
  - platform: gpio
    name: "Exhaust Fan Running"
    id: exhaust_fan_running

  - platform: gpio
    name: "Pressure Switch"
    id: pressure_switch

  - platform: gpio
    name: "Flame Sensor"
    id: flame_sensor
```

### Additional Monitoring
- Runtime tracking
- Cycle counts
- Temperature rise (supply - return)
- Efficiency metrics
- Alert on abnormal conditions
- Filter change reminders based on runtime

## Next Steps

When in garage, collect:
1. Furnace model number and data plate photo
2. Existing control board wiring diagram (usually inside panel door)
3. Photos of all wire connections
4. Blower motor amperage rating
5. Confirmation of safety switch types (NO/NC)
6. Measurements for additional sensor locations

## References

- **Furnace Specifications:** `/esphome/FURNACE-SPECS.md` - Complete control board, gas valve, and wiring details
- **Furnace Photos:** `/esphome/Pictures/` - Control board and nameplate photos
- ESPHome Climate Component: https://esphome.io/components/climate/
- ESPHome Thermostat: https://esphome.io/components/climate/thermostat.html
- Relay specifications: SRD-05VDC-SL-C datasheet
- Home Assistant integration: Native ESPHome integration
- **Replacement Board:** White-Rodgers 50A55-743 (recommended by HVAC tech)

## Notes

- **Experience:** 20 years low voltage wiring background
- **Approach:** Conservative, safety-first implementation
- **Testing:** Monitor-only mode first, then simple thermostat mode, then advanced features
- **Documentation:** Update this file as project progresses
- **Maintenance:** Log all changes and testing results

---

*Last Updated: 2025-11-28*
*Status: Planning Phase*
