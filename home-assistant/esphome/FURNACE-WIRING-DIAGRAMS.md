# Furnace Hybrid Control - Wiring Diagrams

## Overview

This document provides detailed wiring diagrams for the hybrid furnace control system using ESP32 + salvaged White-Rodgers relay board.

**CRITICAL SAFETY NOTES:**
- Turn off ALL power before wiring
- Use lockout/tagout on circuit breakers
- Verify no voltage with multimeter before touching wires
- Have a licensed electrician review if unsure
- Local codes may require permits

---

## Diagram 1: Overall System Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │         120VAC MAINS (FURNACE POWER)        │
                    └────────┬────────────────────┬────────────────┘
                             │                    │
                    ┌────────▼────────┐  ┌────────▼──────────────┐
                    │   TRANSFORMER   │  │  MANUAL DISCONNECT    │
                    │  120VAC → 24VAC │  │    (EMERGENCY OFF)    │
                    └────────┬────────┘  └───────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   24VAC SUPPLY  │
                    │   (R & C)       │
                    └────┬────────┬───┘
                         │        │
           ┌─────────────┘        └────────────────┐
           │                                        │
    ┌──────▼──────────┐                   ┌────────▼────────────┐
    │  ESP32 SYSTEM   │                   │  HARDWARE INTERLOCKS │
    │  - Control      │                   │  (Safety Switches)   │
    │  - Monitoring   │                   │  → Gas Valve         │
    └──────┬──────────┘                   └─────────────────────┘
           │
           │ 24VAC Control Signals
           │
    ┌──────▼──────────────────────┐
    │  SALVAGED RELAY BOARD       │
    │  - Inducer Relay (120VAC)   │
    │  - Blower Relay (120VAC)    │
    └──────┬──────────────────────┘
           │
           │ 120VAC Power
           │
    ┌──────▼──────────┐
    │  FURNACE LOADS  │
    │  - Inducer Motor│
    │  - Blower Motor │
    └─────────────────┘
```

---

## Diagram 2: Power Distribution (120VAC & 24VAC)

```
MAINS POWER (120VAC)
│
├─── Manual Disconnect Switch ───┐
│                                 │
│                          ┌──────▼──────────────┐
│                          │   TRANSFORMER       │
│                          │   Primary: 120VAC   │
│                          │   Secondary: 24VAC  │
│                          └──────┬──────────────┘
│                                 │
│                          24VAC Output
│                          ├─ R (Hot - Red)
│                          └─ C (Common - Blue/Black)
│
├─── Salvaged Inducer Relay ──── Inducer Motor (120VAC, ~3-5A)
│         (NO contact)
│
└─── Salvaged Blower Relay ───── Blower Motor (120VAC, ~5-8A)
          (NO contact)


24VAC DISTRIBUTION (from Transformer Secondary)
│
├─── ESP32 Power Supply (24VAC → 5VDC/3.3VDC)
│
├─── ESP32 Relay Board Common (for control signals)
│
├─── Salvaged Relay Coils (triggered by ESP32)
│    ├─ Inducer Relay Coil
│    └─ Blower Relay Coil
│
└─── Gas Valve Circuit (via safety interlocks)
     │
     └─── R (24VAC) → Limit Switch → Rollout → Pressure → Gas Valve → C
```

---

## Diagram 3: ESP32 Relay Board Connections

```
ESP32 8-CHANNEL RELAY BOARD (5V Logic)
┌─────────────────────────────────────────────────────────────┐
│  VCC: +5VDC (from ESP32 or separate supply)                 │
│  GND: Ground (common with ESP32)                            │
│  IN1-IN8: Control signals from ESP32 GPIO (3.3V/LOW active)│
└─────────────────────────────────────────────────────────────┘

RELAY CHANNEL ASSIGNMENTS:
┌─────────┬──────────────────┬─────────────────────────────┐
│ Relay # │ Function         │ ESP32 GPIO                  │
├─────────┼──────────────────┼─────────────────────────────┤
│ 1       │ Garage Door N    │ GPIO XX (existing)          │
│ 2       │ Garage Door S    │ GPIO XX (existing)          │
│ 3       │ Bay Light N      │ GPIO XX (existing)          │
│ 4       │ Bay Light S      │ GPIO XX (existing)          │
│ 5       │ Workbench Light  │ GPIO XX (existing)          │
│ 6       │ INDUCER CONTROL  │ GPIO 25 (new - furnace)     │
│ 7       │ BLOWER CONTROL   │ GPIO 26 (new - furnace)     │
│ 8       │ Reserved         │ GPIO 27 (reserved)          │
└─────────┴──────────────────┴─────────────────────────────┘

RELAY 6 WIRING (INDUCER CONTROL):
┌─────────────────────────────────────────────────────┐
│  Relay 6 (SRD-05VDC-SL-C)                           │
│                                                     │
│  COM ───┬─── 24VAC "R" (from transformer)          │
│  NO ────┘                                           │
│         │                                           │
│         └─── To Salvaged Inducer Relay Coil (+)    │
│                                                     │
│  Salvaged Relay Coil (-) ─── 24VAC "C" (common)   │
└─────────────────────────────────────────────────────┘

RELAY 7 WIRING (BLOWER CONTROL):
┌─────────────────────────────────────────────────────┐
│  Relay 7 (SRD-05VDC-SL-C)                           │
│                                                     │
│  COM ───┬─── 24VAC "R" (from transformer)          │
│  NO ────┘                                           │
│         │                                           │
│         └─── To Salvaged Blower Relay Coil (+)     │
│                                                     │
│  Salvaged Relay Coil (-) ─── 24VAC "C" (common)   │
└─────────────────────────────────────────────────────┘
```

---

## Diagram 4: ESP32 GPIO Sensor Inputs (with Optoisolators)

**CRITICAL: Use optoisolators to protect ESP32 from 24VAC/120VAC**

```
PRESSURE SWITCH → ESP32 GPIO 16
┌────────────────────────────────────────────────────────┐
│                                                        │
│  Pressure Switch (Normally Open)                      │
│  ├─── Terminal 1 ─── 24VAC "R"                       │
│  └─── Terminal 2 ─┬─── To Optoisolator Input         │
│                    │                                   │
│  ┌─────────────────▼──────────────┐                  │
│  │  OPTOISOLATOR (PC817 or equiv) │                  │
│  │                                 │                  │
│  │  Input Side (24VAC):            │                  │
│  │    Pin 1 (Anode) ─── 24VAC via resistor (1kΩ)   │
│  │    Pin 2 (Cathode) ─── 24VAC "C"                 │
│  │                                 │                  │
│  │  Output Side (Isolated 3.3V):   │                  │
│  │    Pin 3 (Emitter) ─── GND      │                  │
│  │    Pin 4 (Collector) ─┬─ 10kΩ pullup to 3.3V     │
│  │                        └─ ESP32 GPIO 16           │
│  └─────────────────────────────────┘                  │
│                                                        │
└────────────────────────────────────────────────────────┘

LIMIT SWITCH → ESP32 GPIO 17
┌────────────────────────────────────────────────────────┐
│  Same optoisolator circuit as above                    │
│  Limit Switch (Normally Closed) → GPIO 17              │
│  Logic: Open = overheat condition (emergency stop)     │
└────────────────────────────────────────────────────────┘

FLAME SENSOR → ESP32 GPIO 18 (Analog/Digital)
┌────────────────────────────────────────────────────────┐
│  Flame sensor provides 0-5VDC or current signal        │
│  May require voltage divider if >3.3V                  │
│  Check original board for flame sensor circuit         │
│  Optoisolator may not be needed if already isolated    │
└────────────────────────────────────────────────────────┘

ROLLOUT SWITCH → ESP32 GPIO 19
┌────────────────────────────────────────────────────────┐
│  Same optoisolator circuit as pressure switch          │
│  Rollout Switch (Normally Closed) → GPIO 19            │
│  Logic: Open = flame rollout detected (emergency)      │
└────────────────────────────────────────────────────────┘

PIN SUMMARY:
┌──────────┬─────────────────┬─────────┬──────────────────┐
│ ESP32    │ Function        │ Type    │ Logic            │
│ GPIO     │                 │         │                  │
├──────────┼─────────────────┼─────────┼──────────────────┤
│ GPIO 16  │ Pressure Switch │ Input   │ HIGH=closed (OK) │
│ GPIO 17  │ Limit Switch    │ Input   │ HIGH=closed (OK) │
│ GPIO 18  │ Flame Sensor    │ ADC/In  │ Varies           │
│ GPIO 19  │ Rollout Switch  │ Input   │ HIGH=closed (OK) │
│ GPIO 25  │ Inducer Relay   │ Output  │ LOW=activate     │
│ GPIO 26  │ Blower Relay    │ Output  │ LOW=activate     │
│ GPIO 27  │ Reserved        │ Output  │ N/A              │
└──────────┴─────────────────┴─────────┴──────────────────┘
```

---

## Diagram 5: Hardware Safety Interlock Circuit

**THIS CIRCUIT MUST WORK INDEPENDENTLY OF ESP32**

```
CRITICAL GAS VALVE SAFETY CIRCUIT (24VAC)
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  24VAC "R" (Hot)                                           │
│      │                                                      │
│      ├──── Limit Switch (NC) ─────┐                       │
│      │                              │                       │
│      │    (Opens on overheat)      │                       │
│      │                              │                       │
│      ├──── Rollout Switch (NC) ────┤                       │
│      │                              │                       │
│      │    (Opens on flame rollout) │                       │
│      │                              │                       │
│      ├──── Pressure Switch (NO) ───┤                       │
│      │                              │                       │
│      │    (Closes when inducer     │                       │
│      │     creates proper vacuum)  │                       │
│      │                              │                       │
│      └─────────────────────────────▼───── Gas Valve Coil  │
│                                                       │     │
│                                       24VAC "C" ◄─────┘     │
│                                       (Common)              │
│                                                             │
│  OPERATION:                                                │
│  - ALL switches must be in correct state for gas valve    │
│  - If ANY switch opens → gas valve loses power → closes   │
│  - Works even if ESP32 completely fails                   │
│  - This is your primary safety system                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘

NOTE: ESP32 monitors these same switches but does NOT control
      the gas valve directly. Hardware interlocks are backup.
```

---

## Diagram 6: Salvaged Relay Board Connections

**From White-Rodgers 50A-LT735 Control Board**

```
SALVAGED COMPONENTS (to be removed from original board):
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  ┌────────────────────────────────────────┐             │
│  │  INDUCER RELAY (HVAC-rated)            │             │
│  │                                         │             │
│  │  Coil (24VAC):                          │             │
│  │    Terminal 1 ─── From ESP32 Relay 6   │             │
│  │    Terminal 2 ─── 24VAC "C" (common)   │             │
│  │                                         │             │
│  │  Contacts (120VAC NO):                  │             │
│  │    COM ─── 120VAC Hot                  │             │
│  │    NO ──── Inducer Motor Hot           │             │
│  │                                         │             │
│  │  Inducer Motor Neutral ─── 120VAC Neut │             │
│  └────────────────────────────────────────┘             │
│                                                          │
│  ┌────────────────────────────────────────┐             │
│  │  BLOWER RELAY (HVAC-rated)             │             │
│  │                                         │             │
│  │  Coil (24VAC):                          │             │
│  │    Terminal 1 ─── From ESP32 Relay 7   │             │
│  │    Terminal 2 ─── 24VAC "C" (common)   │             │
│  │                                         │             │
│  │  Contacts (120VAC NO):                  │             │
│  │    COM ─── 120VAC Hot                  │             │
│  │    NO ──── Blower Motor Hot            │             │
│  │                                         │             │
│  │  Blower Motor Neutral ─── 120VAC Neut  │             │
│  └────────────────────────────────────────┘             │
│                                                          │
└──────────────────────────────────────────────────────────┘

IDENTIFICATION STEPS:
1. Photograph original board before removal
2. Use multimeter to identify relay coils (typically 200-500Ω)
3. Trace which relay controls inducer vs blower
4. Label all wires before disconnecting
5. Test relays on bench before installation
```

---

## Diagram 7: Complete System Wiring (Simplified)

```
┌────────────────────────────────────────────────────────────────┐
│                     COMPLETE FURNACE CONTROL                   │
└────────────────────────────────────────────────────────────────┘

120VAC MAINS
 │
 ├─ Transformer ──→ 24VAC
 │                   │
 │                   ├─ ESP32 Power Supply (24VAC→5V→3.3V)
 │                   │   │
 │                   │   └─ ESP32 Board
 │                   │       │
 │                   │       ├─ GPIO 16 ◄── Pressure Switch (via opto)
 │                   │       ├─ GPIO 17 ◄── Limit Switch (via opto)
 │                   │       ├─ GPIO 18 ◄── Flame Sensor (via opto)
 │                   │       ├─ GPIO 19 ◄── Rollout Switch (via opto)
 │                   │       │
 │                   │       ├─ GPIO 25 ──► Relay 6 (Inducer)
 │                   │       ├─ GPIO 26 ──► Relay 7 (Blower)
 │                   │       └─ GPIO 27 ──► Relay 8 (Reserved)
 │                   │
 │                   ├─ Relay 6 COM/NO ──► Salvaged Inducer Relay Coil
 │                   ├─ Relay 7 COM/NO ──► Salvaged Blower Relay Coil
 │                   │
 │                   └─ Gas Valve Circuit
 │                       24V → Limit → Rollout → Pressure → Valve → C
 │
 ├─ Salvaged Inducer Relay Contact ──→ Inducer Motor (120VAC)
 │
 └─ Salvaged Blower Relay Contact ──→ Blower Motor (120VAC)
```

---

## Diagram 8: Optoisolator Circuit Detail

```
OPTOISOLATOR CIRCUIT (PC817 or 4N35)
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  24VAC INPUT SIDE:                                        │
│                                                            │
│   24VAC ───┬─── 1kΩ Resistor ─── PC817 Pin 1 (Anode)    │
│            │                                               │
│            └─── Bridge Rectifier (if AC input)            │
│                     │                                      │
│   Common ──────────┴─── PC817 Pin 2 (Cathode)            │
│                                                            │
│  ┌──────────────────────────────────────┐                │
│  │   PC817 OPTOISOLATOR                 │                │
│  │   ┌──────────────────────┐           │                │
│  │   │  LED Side  │  Trans  │           │                │
│  │   │            │  Side   │           │                │
│  │   │  1 ●    ● 4          │           │                │
│  │   │  2 ●    ● 3          │           │                │
│  │   └──────────────────────┘           │                │
│  └──────────────────────────────────────┘                │
│                                                            │
│  ESP32 OUTPUT SIDE (ISOLATED):                            │
│                                                            │
│   +3.3V ─── 10kΩ Pullup ─── PC817 Pin 4 (Collector)      │
│                               │                            │
│                               ├─── ESP32 GPIO              │
│                               │                            │
│   GND ─────────────────────── PC817 Pin 3 (Emitter)       │
│                                                            │
│  OPERATION:                                                │
│  - 24VAC input energizes LED side                         │
│  - LED activates phototransistor                          │
│  - Transistor pulls GPIO LOW (or HIGH depending on logic) │
│  - Complete electrical isolation between 24VAC and ESP32  │
│                                                            │
└────────────────────────────────────────────────────────────┘

COMPONENTS NEEDED (per sensor):
- 1x PC817 or 4N35 optoisolator
- 1x 1kΩ resistor (for 24VAC side)
- 1x 10kΩ resistor (pullup for ESP32 side)
- Optional: Bridge rectifier for AC inputs
```

---

## Bill of Materials (BOM)

### Components Needed for Hybrid System

**Existing (from garage-controller.yaml):**
- [x] ESP32-WROOM-32E development board
- [x] 8-channel 5V relay board (SRD-05VDC-SL-C)
- [x] AHT20+BMP280 temperature/humidity sensors

**To Salvage from White-Rodgers 50A-LT735:**
- [ ] Inducer motor relay (HVAC-rated, 120VAC)
- [ ] Blower motor relay (HVAC-rated, 120VAC)
- [ ] Transformer (120VAC → 24VAC) - or reuse existing
- [ ] Possibly flame sensor circuit

**New Components Needed:**

**Power & Isolation:**
- [ ] 24VAC to 5VDC power supply (for ESP32)
  - Minimum 2A capacity
  - Example: HLK-PM01 or similar
- [ ] 4x PC817 or 4N35 optoisolators (for safety sensors)
- [ ] 4x 1kΩ resistors (optoisolator input side)
- [ ] 4x 10kΩ resistors (optoisolator pullup)

**Wiring & Connectors:**
- [ ] 18 AWG wire (120VAC power - red/black/white/green)
- [ ] 20-22 AWG wire (24VAC control - various colors)
- [ ] 24-26 AWG wire (3.3V logic - ribbon cable OK)
- [ ] Terminal blocks (screw terminals for easy connection)
- [ ] Wire ferrules (crimp-on for terminal blocks)
- [ ] Heat shrink tubing (various sizes)
- [ ] Cable ties / zip ties

**Enclosure & Mounting:**
- [ ] Project enclosure (to house ESP32 and relay board)
- [ ] DIN rail mounts (optional, for clean installation)
- [ ] Standoffs for mounting boards
- [ ] Ventilation (relays generate heat)

**Tools Required:**
- [ ] Multimeter (voltage, continuity, resistance)
- [ ] Wire strippers
- [ ] Crimping tool (for ferrules)
- [ ] Screwdrivers (Phillips and flat)
- [ ] Soldering iron (for optoisolator circuit)
- [ ] Heat gun (for heat shrink)
- [ ] Label maker (for wire identification)

**Safety Equipment:**
- [ ] Non-contact voltage tester
- [ ] Fire extinguisher (Class C - electrical)
- [ ] Carbon monoxide detector
- [ ] Lockout/tagout tags for circuit breaker

---

## Wire Color Code Recommendations

### 120VAC Wiring (Use NEC Standard Colors):
- **Hot (Line):** Black
- **Neutral:** White
- **Ground:** Green or bare copper

### 24VAC Wiring:
- **R (Hot):** Red
- **C (Common):** Blue or Black
- **W (Heat call):** White
- **G (Fan):** Green
- **Y (Cool):** Yellow

### ESP32 Logic (3.3V):
- **Power (+3.3V):** Red
- **Ground:** Black
- **GPIO signals:** Various colors (label each)

### Optoisolator Connections:
- **Input side (24VAC):** Match 24VAC color code
- **Output side (ESP32):** Use distinct colors, label clearly

---

## Installation Sequence Checklist

### Pre-Installation:
- [ ] Review all diagrams
- [ ] Gather all components
- [ ] Test salvaged relays on bench
- [ ] Build optoisolator circuits on breadboard
- [ ] Test ESP32 code with simulated inputs (LEDs)

### Phase 1 - Bench Test:
- [ ] Wire ESP32 to relay board
- [ ] Wire optoisolators
- [ ] Use 24VAC wall adapter for testing (NOT furnace)
- [ ] Verify all GPIO inputs read correctly
- [ ] Verify all relay outputs work
- [ ] Test watchdog and failsafe modes

### Phase 2 - Prepare Salvage:
- [ ] Turn off furnace power (breaker + lockout)
- [ ] Photograph all original wiring
- [ ] Label every wire before disconnecting
- [ ] Remove White-Rodgers control board
- [ ] Identify and extract relays
- [ ] Test relay coil resistance (should be 200-500Ω)
- [ ] Test relay contacts (continuity when energized)

### Phase 3 - Install ESP32 System:
- [ ] Mount ESP32 and relay board in enclosure
- [ ] Install optoisolator circuit board
- [ ] Route 24VAC power to enclosure
- [ ] Connect safety sensor inputs (DO NOT POWER YET)
- [ ] Label all connections

### Phase 4 - Wire Salvaged Relays:
- [ ] Mount salvaged relay board near furnace
- [ ] Wire relay coils to ESP32 relay outputs (24VAC)
- [ ] Wire relay contacts to inducer motor (120VAC)
- [ ] Wire relay contacts to blower motor (120VAC)
- [ ] Triple-check all connections

### Phase 5 - Safety Interlocks:
- [ ] Wire limit switch to gas valve circuit
- [ ] Wire rollout switch to gas valve circuit
- [ ] Wire pressure switch to gas valve circuit
- [ ] Test interlock circuit (disconnect each switch, verify gas valve loses power)

### Phase 6 - First Power-On:
- [ ] Final visual inspection
- [ ] Verify all grounds connected
- [ ] Restore 120VAC power
- [ ] Check transformer output (should be ~24VAC)
- [ ] Check ESP32 power supply (should be 5VDC and 3.3VDC)
- [ ] Monitor ESP32 serial console for errors

### Phase 7 - Testing:
- [ ] Monitor-only mode (ESP32 logs but doesn't control)
- [ ] Manually test each relay (short duration)
- [ ] Test safety lockouts (trigger each sensor)
- [ ] First automatic cycle (closely supervised)
- [ ] 24-hour monitored operation
- [ ] Normal operation

---

## Troubleshooting Guide

### Problem: ESP32 won't boot
- Check 5VDC power supply voltage
- Check 3.3V regulator on ESP32 board
- Disconnect all GPIO connections and retry
- Check for short circuits

### Problem: Relay doesn't activate
- Check GPIO output voltage (should be HIGH when off, LOW when on)
- Check relay coil voltage (should be 5VDC when activated)
- Check relay LED indicator
- Verify relay is not damaged

### Problem: Optoisolator not working
- Check input voltage (24VAC should be present)
- Check resistor values
- Test LED side with multimeter (forward voltage drop ~1.2V)
- Test transistor side (should conduct when LED lit)

### Problem: Gas valve won't open
- Check safety interlock circuit (all switches must be closed)
- Measure voltage at gas valve (should be 24VAC)
- Check gas valve coil resistance (typically 100-500Ω)
- Verify gas is turned on

### Problem: Pressure switch won't close
- Check inducer motor is running
- Check for blockages in vent pipe
- Check pressure switch hose connections
- Pressure switch may be faulty

---

## Safety Reminders

**BEFORE EVERY SESSION:**
1. Turn off power at breaker
2. Use lockout/tagout
3. Verify no voltage with multimeter
4. Have fire extinguisher ready
5. Ensure good ventilation

**DURING TESTING:**
1. Never leave running furnace unattended initially
2. Monitor for unusual smells, sounds, heat
3. Have phone ready to call for help
4. Know where gas shutoff valve is located

**EMERGENCY PROCEDURES:**
1. **Smell gas:** Turn off gas valve, evacuate, call gas company
2. **Smell burning:** Kill power, check for hot components
3. **CO alarm:** Evacuate immediately, call fire department
4. **Furnace won't shut off:** Kill power at breaker, call HVAC tech

---

*Document Created: 2025-11-28*
*Status: Design Phase - For Reference Only*
*DO NOT BEGIN WIRING WITHOUT THOROUGH REVIEW*
