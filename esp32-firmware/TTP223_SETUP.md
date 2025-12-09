# TTP223 Touch Sensor Setup Guide

## Overview

Este guia descreve como conectar e configurar o sensor de toque capacitivo TTP223-HA6 no ESP32 para detecção de uso do colete ortopédico.

## Hardware Requirements

- **TTP223-HA6 Capacitive Touch Sensor Module**
- **ESP32-WROOM-32 Development Board**
- **3 jumper wires** (female-to-female or female-to-male depending on your setup)
- **Conductive material** (copper tape, aluminum foil, or conductive fabric) for touch pad

## TTP223 Module Specifications

| Parameter | Value |
|-----------|-------|
| Operating Voltage | 2.0V - 5.5V |
| Output Logic | Digital (HIGH/LOW) |
| Response Time | < 220ms |
| Power Consumption | < 1.5µA (standby) |
| Touch Sensitivity | Adjustable |
| Output Mode | Toggle or Momentary |

## Pin Configuration

### TTP223 Pinout

```
┌─────────────────┐
│    TTP223-HA6   │
│                 │
│  VCC  GND  SIG  │
└──┬────┬────┬────┘
   │    │    │
   │    │    └─── Signal Output (to ESP32 GPIO)
   │    └──────── Ground
   └───────────── Power (3.3V)
```

### Connection Diagram

```
TTP223          ESP32-WROOM-32
┌─────┐         ┌──────────┐
│ VCC │────────▶│ 3.3V     │
│ GND │────────▶│ GND      │
│ SIG │────────▶│ GPIO 4   │
└─────┘         └──────────┘
```

## Physical Connection Steps

### 1. Power Connection

Connect TTP223 **VCC** to ESP32 **3.3V** pin:
- Use a red jumper wire for easy identification
- Ensure stable 3.3V supply (do not use 5V as it may damage the sensor)

### 2. Ground Connection

Connect TTP223 **GND** to ESP32 **GND** pin:
- Use a black jumper wire
- Ensure good ground connection for stable operation

### 3. Signal Connection

Connect TTP223 **SIG** (or **OUT**) to ESP32 **GPIO 4**:
- Use any color jumper wire (yellow/green recommended)
- This is the digital output that goes HIGH when touch is detected

## Touch Pad Setup

### Option 1: Using Copper Tape (Recommended)

1. Cut a piece of copper tape approximately 3cm x 3cm
2. Stick it to the inside of the brace where it contacts the patient's skin
3. Solder a wire from the copper tape to the TTP223 touch pad
4. Insulate the solder joint with heat shrink or electrical tape

### Option 2: Using Conductive Fabric

1. Cut conductive fabric to desired size (3cm x 3cm minimum)
2. Sew or glue it to the inside of the brace
3. Connect a wire from the fabric to the TTP223 touch pad
4. Ensure good electrical contact

### Option 3: Direct PCB Touch Pad

1. Use the TTP223 module's built-in touch pad
2. Mount the module directly inside the brace
3. Ensure the touch pad faces the patient's skin
4. Add a thin insulating layer if needed (< 3mm)

## Module Configuration

The TTP223 module has two configuration options via solder jumpers on the back:

### A: Output Mode

- **Default (Open)**: Momentary mode - Output HIGH only while touched
- **Closed**: Toggle mode - Output toggles between HIGH/LOW on each touch

**For this project**: Use **Momentary mode (default)** - do not close this jumper

### B: Power-On State

- **Default (Open)**: Output LOW on power-up
- **Closed**: Output HIGH on power-up

**For this project**: Use **default (open)** - do not close this jumper

## Testing the Connection

### 1. Visual Test

Upload this simple test sketch to verify the connection:

```cpp
#define TOUCH_PIN 4

void setup() {
  Serial.begin(115200);
  pinMode(TOUCH_PIN, INPUT_PULLDOWN);
  Serial.println("TTP223 Touch Test");
}

void loop() {
  int touchState = digitalRead(TOUCH_PIN);
  
  if (touchState == HIGH) {
    Serial.println("✓ TOUCH DETECTED");
  } else {
    Serial.println("○ No touch");
  }
  
  delay(200);
}
```

### 2. Expected Behavior

- **No touch**: Serial monitor shows "○ No touch"
- **Touch detected**: Serial monitor shows "✓ TOUCH DETECTED"
- **Response time**: Should respond within 220ms of touch

### 3. Troubleshooting

| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| Always HIGH | Wiring error or module stuck | Check connections, power cycle |
| Always LOW | No power or bad connection | Verify 3.3V supply, check wiring |
| Intermittent | Loose connection | Secure all connections, check solder joints |
| No response | Wrong GPIO or dead module | Verify GPIO 4, try different module |

## Sensitivity Adjustment

The TTP223 sensitivity can be adjusted by changing the onboard resistor:

- **Higher resistance** = More sensitive (detects through thicker materials)
- **Lower resistance** = Less sensitive (requires direct contact)

**Default**: 1MΩ (suitable for most applications)

**For brace application**: Default sensitivity should work well through thin fabric (< 2mm)

## Integration with Main Firmware

The main firmware (`main.cpp`) already includes TTP223 support:

```cpp
// Pin definition
const int TOUCH_SENSOR_PIN = 4;

// In setup()
pinMode(TOUCH_SENSOR_PIN, INPUT_PULLDOWN);

// In readSensors()
data.touchDetected = digitalRead(TOUCH_SENSOR_PIN);

// In detectUsage()
if (data.touchDetected && data.temperature >= 30.0 && data.temperature <= 40.0) {
    // Patient is wearing the brace
}
```

## Mounting Recommendations

### Inside the Brace

1. **Position**: Place touch pad where it reliably contacts skin
2. **Protection**: Use thin protective layer to prevent sweat damage
3. **Wiring**: Route wires along brace structure, secure with zip ties
4. **Strain relief**: Add strain relief at connection points

### Module Placement

- Mount TTP223 module near ESP32 to minimize wire length
- Keep away from high-voltage components
- Protect from moisture with conformal coating or enclosure

## Power Consumption

- **Active (touched)**: ~1.5mA
- **Standby (not touched)**: < 1.5µA
- **Impact on battery**: Negligible (< 0.01% of total consumption)

## Advantages Over Other Methods

| Method | Pros | Cons |
|--------|------|------|
| **TTP223 (Capacitive)** | ✓ No wear<br>✓ Reliable<br>✓ Low power<br>✓ Simple | - Requires skin contact |
| FSR (Force Sensor) | ✓ Pressure sensing | - Mechanical wear<br>- Requires ADC<br>- Calibration needed |
| Temperature Only | ✓ No extra hardware | - False positives<br>- Slow response |

## Safety Considerations

- ✓ Low voltage (3.3V) - safe for patient contact
- ✓ No exposed conductors - use proper insulation
- ✓ Medical-grade materials recommended for touch pad
- ✓ Regular inspection for wear and damage

## Maintenance

- **Weekly**: Check connections and wiring
- **Monthly**: Clean touch pad with isopropyl alcohol
- **Quarterly**: Inspect for corrosion or damage
- **Annually**: Replace touch pad if worn

## References

- [TTP223 Datasheet](esp32-firmware/.docs/TTP223-HA6_V1.1_EN.pdf)
- [ESP32 GPIO Reference](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/gpio.html)

## Support

For issues or questions:
1. Check troubleshooting section above
2. Verify all connections with multimeter
3. Test with simple sketch before integrating
4. Check serial monitor for debug messages
