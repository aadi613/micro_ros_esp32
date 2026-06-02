#!/bin/bash
# =============================================================================
# 01_check_esp32.sh
# Step 3: Verify ESP32 Connection on Raspberry Pi
# Run this AFTER connecting ESP32 to the Pi via USB cable.
# =============================================================================

echo "============================================="
echo "  Checking for ESP32 USB Serial Device"
echo "============================================="

# List all tty devices
echo ""
echo "[INFO] All available serial ports:"
ls /dev/tty* 2>/dev/null || echo "[WARN] No tty devices found at all."

echo ""
echo "[INFO] Scanning for ESP32 (ttyUSB* or ttyACM*)..."
echo ""

FOUND=0

# Check for ttyUSB devices
if ls /dev/ttyUSB* 1>/dev/null 2>&1; then
    echo "[OK] Found ttyUSB device(s):"
    ls /dev/ttyUSB*
    FOUND=1
fi

# Check for ttyACM devices
if ls /dev/ttyACM* 1>/dev/null 2>&1; then
    echo "[OK] Found ttyACM device(s):"
    ls /dev/ttyACM*
    FOUND=1
fi

echo ""
if [ $FOUND -eq 1 ]; then
    echo "[SUCCESS] ESP32 detected. Use the port above when starting the micro-ROS Agent."
    echo "          Typical command:"
    echo "          ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0"
else
    echo "[ERROR] No ESP32 serial device found."
    echo ""
    echo "  Troubleshooting:"
    echo "  1. Make sure the USB cable supports DATA (not just charging)."
    echo "  2. Try: sudo dmesg | tail -20   -- to see USB events."
    echo "  3. Try a different USB port on the Pi."
    echo "  4. Make sure the ESP32 is powered on."
fi

echo ""
echo "============================================="
