# Furnace Hybrid Control System Design

## Overview

This document outlines the hybrid control architecture for the Amana GCCA090BX40 furnace, combining ESP32-based control with salvaged components from the White-Rodgers 50A-LT735 control board.

## Design Philosophy

**Hybrid Approach:**
- ESP32 handles sequencing logic and 24VAC control signals
- Salvaged HVAC-rated relays handle high-current 120VAC loads (inducer, blower)
- Hardware safety interlocks remain independent of ESP32
- Best balance of control, safety, and simplicity

## Component Allocation

### From Original White-Rodgers Board (Salvage)

**High-Current Relays:**
1. **Inducer Motor Relay** (~120VAC, 3-5A)
   - HVAC-rated relay from original board
   - Triggered by ESP32 via 24VAC signal
   - Mechanically robust for motor loads

2. **Blower Motor Relay** (~120VAC, 5-8A)
   - HVAC-rated relay from original board
   - Triggered by ESP32 via 24VAC signal
   - Handles inductive motor load safely

**Power Supply:**
- **Transformer** (120VAC → 24VAC)
   - Reuse original transformer
   - Powers: gas valve, control circuits, ESP32 power supply

**Potentially Salvageable:**
- Flame sensor circuit (if isolated/identifiable)
- Additional safety relay circuits
- LED indicators

### ESP32 Control (New)

**8-Channel 5V Relay Board (SRD-05VDC-SL-C):**

**Currently Allocated:**
- Relay 1-2: Garage doors
- Relay 3-5: Lighting

**Furnace Allocation:**
- **Relay 6: Call for Heat** - Triggers inducer sequence
- **Relay 7: Blower Control** - Activates blower after heat delay
- **Relay 8: Reserved** - Future use (zone damper, aux heat, etc.)

**Relay Ratings:**
- 10A @ 250VAC (resistive)
- ~5A (inductive)
- **Suitable for 24VAC control signals** ✓
- **NOT suitable for direct 120VAC motor loads** ✗

## Furnace Operating Sequence

### Normal Heat Cycle

1. **Thermostat calls for heat** (ESP32 climate component decides)

2. **Pre-purge** (Safety check)
   - ESP32 verifies all safety sensors OK
   - Pressure switch OPEN (no flow yet)
   - Limit switches CLOSED (not overheated)
   - No flame detected

3. **Inducer Motor Start** (ESP32 Relay 6 → Salvaged Inducer Relay)
   - ESP32 closes Relay 6
   - 24VAC signal triggers salvaged inducer relay
   - Inducer motor starts (120VAC)
   - Wait 30-60 seconds for pressure switch to close

4. **Pressure Switch Verification**
   - ESP32 monitors pressure switch input
   - If switch doesn't close in 60 sec → LOCKOUT
   - If switch closes → proceed

5. **Hot Surface Ignitor** (Controlled by gas valve or separate relay)
   - Heat ignitor for 15-30 seconds
   - ESP32 monitors ignitor current/voltage (optional)

6. **Gas Valve Open**
   - After ignitor warm-up, open gas valve (24VAC)
   - Controlled by ESP32 or integrated with ignitor circuit
   - Gas flows, ignites on hot surface

7. **Flame Verification** (5-10 seconds)
   - Flame sensor detects flame (flame rod current)
   - ESP32 monitors flame sensor
   - If NO flame detected in 10 sec → close gas valve, LOCKOUT
   - If flame detected → proceed

8. **Heat Delay** (45-90 seconds)
   - Allow heat exchanger to warm up
   - Prevents blowing cold air
   - ESP32 timer-based or temperature sensor

9. **Blower Motor Start** (ESP32 Relay 7 → Salvaged Blower Relay)
   - ESP32 closes Relay 7
   - 24VAC signal triggers salvaged blower relay
   - Blower motor starts (120VAC)
   - Circulates heated air

10. **Heating Mode**
    - Inducer running
    - Gas valve open
    - Flame present
    - Blower running
    - Monitor all safety sensors continuously

11. **Thermostat Satisfied** (ESP32 decides heat no longer needed)

12. **Gas Valve Close**
    - Stop gas flow immediately
    - Flame extinguishes

13. **Post-Purge Blower** (2-5 minutes)
    - Keep blower running to extract remaining heat
    - Inducer may continue or stop (design choice)
    - ESP32 timer-based

14. **System Off**
    - Blower stops
    - Inducer stops
    - Return to standby

### Safety Lockouts

**Conditions that trigger immediate shutdown:**
- Pressure switch opens during operation
- Limit switch opens (overheat)
- Flame lost during gas valve open
- Rollout switch trips
- ESP32 watchdog timeout

**Lockout behavior:**
1. Close gas valve immediately
2. Run blower for cooling (if safe)
3. Stop inducer after purge
4. Flash error code
5. Prevent restart until reset

## Electrical Architecture

### Power Distribution

```
120VAC Mains
│
├─→ Transformer Primary (120VAC)
│   │
│   └─→ Transformer Secondary (24VAC)
│       │
│       ├─→ Gas Valve (24VAC, 0.35A)
│       ├─→ ESP32 Power Supply (24VAC → 5VDC, 3.3VDC)
│       ├─→ Salvaged Relay Coils (24VAC)
│       └─→ Control Circuit Common (C)
│
├─→ Inducer Motor (120VAC, via salvaged relay)
│
└─→ Blower Motor (120VAC, via salvaged relay)
```

### Control Signal Flow

```
ESP32 (3.3V Logic)
│
├─→ Relay 6 (5VDC coil) → 24VAC → Salvaged Inducer Relay → Inducer Motor (120VAC)
│
├─→ Relay 7 (5VDC coil) → 24VAC → Salvaged Blower Relay → Blower Motor (120VAC)
│
└─→ Relay 8 (5VDC coil) → Reserved
```

### Safety Sensor Inputs (to ESP32)

```
Pressure Switch (24VAC or dry contact) → ESP32 GPIO (via optoisolator)
Limit Switch (dry contact) → ESP32 GPIO (via optoisolator)
Flame Sensor (0-5VDC or current loop) → ESP32 ADC or GPIO
Rollout Switch (dry contact) → ESP32 GPIO (via optoisolator)
```

## Safety Architecture

### Hardware Interlocks (CRITICAL)

**Independent of ESP32 - Must fail safe:**

1. **Gas Valve Interlock Series Circuit:**
   ```
   24VAC → Limit Switch → Rollout Switch → Pressure Switch → Gas Valve → Common
   ```
   - If ANY switch opens → gas valve loses power → closes immediately
   - Works even if ESP32 crashes
   - **NON-NEGOTIABLE SAFETY REQUIREMENT**

2. **Manual Shutoff:**
   - Physical switch to disconnect power
   - Accessible without tools
   - Labeled clearly

### Software Interlocks (ESP32)

**Pre-ignition checks:**
- All limit switches closed
- Pressure switch state correct for phase
- No flame present before gas valve opens
- Inducer proven running (pressure switch)

**Runtime monitoring:**
- Continuous flame sensor monitoring
- Pressure switch must stay closed
- Limit switches must stay closed
- Watchdog timer (ESP32 must "pet" watchdog every 5 sec)

**Fault handling:**
- Error codes via LED or Home Assistant notification
- Lockout counter (prevent rapid restart cycles)
- Diagnostic logging to SD card or network

## Wiring Plan

### ESP32 Relay Outputs

| ESP32 Relay | Function | Connects To | Signal Type |
|-------------|----------|-------------|-------------|
| Relay 6 NO  | Call for Heat/Inducer | Salvaged inducer relay coil (+) | 24VAC |
| Relay 6 COM | Common | 24VAC transformer secondary (R) | 24VAC |
| Relay 7 NO  | Blower | Salvaged blower relay coil (+) | 24VAC |
| Relay 7 COM | Common | 24VAC transformer secondary (R) | 24VAC |
| Relay 8     | Reserved | TBD | TBD |

### ESP32 GPIO Inputs (with optoisolators)

| ESP32 GPIO | Function | Sensor | Signal |
|------------|----------|--------|--------|
| GPIO 16    | Pressure Switch | Proves inducer airflow | 24VAC or dry contact |
| GPIO 17    | Limit Switch | High temp cutoff | Dry contact (NO) |
| GPIO 18    | Flame Sensor | Flame detection | 0-3.3V or current |
| GPIO 19    | Rollout Switch | Flame rollout detection | Dry contact (NO) |
| GPIO 21    | Reserved | Future sensor | TBD |

**IMPORTANT:** Use optoisolators (PC817 or similar) to isolate 24VAC/120VAC from ESP32 3.3V logic.

### Salvaged Board Connections

**From White-Rodgers 50A-LT735:**

1. **Identify and label** all relay coils on salvaged board
2. **Trace connections** for:
   - Inducer relay coil (24VAC)
   - Blower relay coil (24VAC)
   - Relay contacts (120VAC to motors)
3. **Desolder/disconnect** original logic board, **keep** relay board
4. **Wire ESP32 relays** to trigger salvaged relay coils

## Implementation Phases

### Phase 1: Bench Testing (SAFE)
- [ ] Wire ESP32 relays to LEDs (no furnace connection)
- [ ] Implement sequence logic in ESPHome
- [ ] Test all safety lockouts with simulated sensors
- [ ] Verify timing sequences
- [ ] Test watchdog and failure modes

### Phase 2: Monitor-Only Installation (SAFE)
- [ ] Install ESP32 in furnace area
- [ ] Wire safety sensor inputs (pressure, limit, flame)
- [ ] Monitor furnace operation WITHOUT controlling it
- [ ] Log sensor states during normal cycles
- [ ] Verify sensor readings match expected behavior
- [ ] Identify any sensor wiring issues

### Phase 3: Salvage and Prepare (MODERATE RISK)
- [ ] Power off furnace and lock out power
- [ ] Remove White-Rodgers 50A-LT735 board
- [ ] Identify and photograph all connections
- [ ] Test salvaged relays on bench (continuity, coil resistance)
- [ ] Mount salvaged relay board in new enclosure
- [ ] Label all connections clearly

### Phase 4: Low-Voltage Integration (MODERATE RISK)
- [ ] Wire ESP32 relay outputs to salvaged relay coils (24VAC only)
- [ ] Wire safety interlock series circuit (limit, rollout, pressure → gas valve)
- [ ] Test control signals with multimeter (NO 120VAC YET)
- [ ] Verify relay coils activate with ESP32 commands
- [ ] Verify hardware interlocks work (disconnect pressure switch, gas valve should lose power)

### Phase 5: Full Integration (HIGH RISK - REQUIRES CARE)
- [ ] Wire 120VAC to inducer motor via salvaged relay
- [ ] Wire 120VAC to blower motor via salvaged relay
- [ ] Triple-check all connections
- [ ] Test with furnace disconnected from ductwork (if possible)
- [ ] Have fire extinguisher ready
- [ ] First test run with close supervision
- [ ] Monitor for 24 hours before trusting

### Phase 6: Optimization (ONGOING)
- [ ] Tune heat delay timings
- [ ] Optimize blower post-purge duration
- [ ] Add temperature-based blower speed control (if variable-speed motor)
- [ ] Multi-zone logic implementation
- [ ] Home Assistant automation integration

## Risk Mitigation

### Critical Safety Measures

1. **Hardware Interlocks:**
   - Limit, rollout, pressure switches in series with gas valve
   - Work independently of ESP32

2. **Fail-Safe Design:**
   - ESP32 crash → relays open → furnace shuts down safely
   - Default state is OFF

3. **Redundant Monitoring:**
   - ESP32 monitors all safety sensors
   - Hardware interlocks provide backup

4. **Testing Protocol:**
   - Bench test before installation
   - Monitor-only phase before control
   - Supervised first runs

5. **Emergency Shutoff:**
   - Clearly labeled manual power disconnect
   - Easy to reach without tools

### Known Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Gas leak | CRITICAL | Hardware interlocks, leak testing, supervision |
| Fire from electrical fault | HIGH | Proper wire sizing, fusing, supervision |
| Carbon monoxide | CRITICAL | CO detector required, pressure switch monitoring |
| ESP32 software bug | MEDIUM | Watchdog timer, extensive testing, hardware interlocks |
| Incorrect wiring | HIGH | Triple-check, peer review, documented wiring diagram |
| Insurance/code issues | MEDIUM | Document professionally, consider UL-listed control board instead |

## Next Steps

1. **Review this design** - Ensure it matches your skill level and comfort
2. **Gather components** - Optoisolators, wire, connectors, enclosure
3. **Create wiring diagram** - Detailed schematic with all connections
4. **Bench test** - Prove ESP32 logic works before installation
5. **Proceed with Phase 1** - Start with safe, reversible steps

## Questions to Answer Before Proceeding

- [ ] Are you comfortable working with 120VAC? (If not, consider thermostat emulation instead)
- [ ] Do you have appropriate tools? (Multimeter, wire strippers, crimpers, etc.)
- [ ] Have you located all safety switches on the furnace?
- [ ] Can you identify inducer and blower motor connections on original board?
- [ ] Do you have a backup heat source if this takes longer than expected?
- [ ] Does your insurance/local codes allow homeowner HVAC modifications?

---

*Document created: 2025-11-28*
*Status: Design Phase - Not Yet Implemented*
*SAFETY WARNING: This involves gas, electricity, and potential fire/CO hazards. Proceed with extreme caution.*
