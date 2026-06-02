# Hardware Setup

> Connect your ESP32 to the Raspberry Pi and verify the serial connection before flashing firmware.

---

## ESP32 Board Overview

The ESP32 is a dual-core 32-bit microcontroller with built-in Wi-Fi and Bluetooth. For this project we use it in **USB-serial mode** — the laptop/Pi communicates with it through a USB-to-UART bridge chip.

```
┌──────────────────────────────────────┐
│              ESP32 Dev Board         │
│                                      │
│  GPIO 2  ●──────── Onboard LED       │
│                                      │
│  TX  ●────────┐                      │
│  RX  ●────────┤ USB-UART Bridge      │
│  GND ●────────┘ (CP2102 or CH340)   │
│                      │               │
│               Micro-USB / USB-C      │
└──────────────────────────────────────┘
                      │
                  USB Cable
                      │
            Raspberry Pi USB Port
                (/dev/ttyUSB0)
```

---

## Requirements

| Item | Notes |
|------|-------|
| ESP32 Dev Board | Any standard ESP32 (38-pin or 30-pin) |
| USB Cable | **Must support data transfer** — not just charging |
| Raspberry Pi | Any model with USB; ROS 2 Docker running |
| Power | USB cable powers the ESP32 from the Pi |

---

## Step 1 — Connect Hardware

1. Plug the ESP32 into the Raspberry Pi using a USB data cable.
2. The ESP32 should power on (a power LED will glow).
3. The Pi will detect a new serial device.

---

## Step 2 — Identify the Serial Port

On the Raspberry Pi:

```bash
ls /dev/tty*
```

Look for:

```
/dev/ttyUSB0     ← CP2102 or similar USB-UART chip
/dev/ttyACM0     ← CH340 or native USB CDC chip
```

**To confirm which device is the ESP32:**

```bash
# Unplug ESP32, run:
ls /dev/tty* > before.txt

# Plug ESP32 back in, run:
ls /dev/tty* > after.txt

# Compare:
diff before.txt after.txt
```

The new entry is your ESP32.

---

## Step 3 — Check USB-UART Driver (if no device appears)

```bash
# See recent USB events
sudo dmesg | tail -30

# Look for lines like:
# usb 1-1.2: new full-speed USB device
# usb 1-1.2: cp210x converter now attached to ttyUSB0
```

**Common USB-UART chips on ESP32 boards:**

| Chip | Port Name | Driver |
|------|-----------|--------|
| CP2102 / CP2104 | `/dev/ttyUSB0` | Built into Linux kernel |
| CH340 / CH341 | `/dev/ttyUSB0` | `ch341` module (usually auto-loaded) |
| FTDI FT232 | `/dev/ttyUSB0` | `ftdi_sio` module |
| Native USB CDC | `/dev/ttyACM0` | Built into kernel |

If no device appears, try:

```bash
# Load CH340 driver
sudo modprobe ch341

# Load CP210x driver
sudo modprobe cp210x

# Or install brltty fix (common on Ubuntu 22.04)
sudo apt remove brltty
```

---

## Step 4 — Set Serial Port Permissions

```bash
# Add user to dialout group (required to access serial ports)
sudo usermod -aG dialout $USER

# Apply without logout
newgrp dialout

# Verify
ls -l /dev/ttyUSB0
# Should show: crw-rw---- 1 root dialout ...
```

---

## Step 5 — Test Serial Communication

```bash
# Install minicom
sudo apt install -y minicom

# Connect to ESP32 at 115200 baud
minicom -D /dev/ttyUSB0 -b 115200

# Press Ctrl+A then X to exit minicom
```

If firmware is running, you should see ESP32 log output.

---

## ESP32 Pin Reference (Commonly Used)

| GPIO | Function | Notes |
|------|----------|-------|
| 2 | Onboard LED | PWM output in PWM_LED_Control module |
| 1 | TX (UART0) | Default serial TX |
| 3 | RX (UART0) | Default serial RX |
| EN | Reset | Pull LOW to reset |
| 0 | Boot mode | Pull LOW to enter flash mode |

---

## Flashing Firmware

To put the ESP32 into flash mode:
1. Hold the **BOOT** button (GPIO 0)
2. Press and release the **EN** (Reset) button
3. Release **BOOT**
4. Run `idf.py flash`

Most modern ESP32 boards with CP2102 do this automatically via DTR/RTS signals.

---

## Hardware Checklist

| Check | Status |
|-------|--------|
| ESP32 powers on (LED blinks) | ✓ |
| `/dev/ttyUSB0` or `/dev/ttyACM0` appears | ✓ |
| User in `dialout` group | ✓ |
| Serial output visible in minicom | ✓ |

---

## Next Step

→ [ESP32 Publisher](../ESP32_Publisher/README.md)
