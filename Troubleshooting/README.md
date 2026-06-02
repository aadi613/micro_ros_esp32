# Troubleshooting

> Quick reference for diagnosing and fixing the most common issues when working with micro-ROS on ESP32 with ROS 2 Humble.

---

## Diagnostic Checklist (Run First)

Before deep-diving, always check these in order:

```bash
# 1. Is Docker running?
sudo docker ps

# 2. Is the container running?
sudo docker ps | grep ros2_humble

# 3. Is ESP32 detected?
ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null

# 4. Is the Agent running? (should be in another terminal)
# If not, start it:
sudo docker exec -it ros2_humble bash -c \
  "source /opt/ros/humble/setup.bash && \
   ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0"

# 5. Are topics visible?
sudo docker exec ros2_humble bash -c \
  "source /opt/ros/humble/setup.bash && ros2 topic list"
```

---

## Error Index

| Error | Jump To |
|-------|---------|
| `ros2: command not found` | [→ Error 1](#error-1-ros2-command-not-found) |
| No serial device | [→ Error 2](#error-2-no-serial-device-found) |
| Agent starts but no topics | [→ Error 3](#error-3-agent-starts-but-no-topics-appear) |
| Only `/parameter_events` visible | [→ Error 4](#error-4-only-parameter_events-and-rosout-visible) |
| Container not running | [→ Error 5](#error-5-docker-container-not-running) |
| `Failed status on line X` | [→ Error 6](#error-6-failed-status-on-line-x-aborting) |
| Firmware won't flash | [→ Error 7](#error-7-firmware-wont-flash) |
| ESP32 keeps rebooting | [→ Error 8](#error-8-esp32-keeps-rebooting-watchdog-reset) |
| Build fails on rclc headers | [→ Error 9](#error-9-build-fails-missing-rclc-headers) |
| Agent exits immediately | [→ Error 10](#error-10-micro-ros-agent-exits-immediately) |

---

## Error 1: `ros2: command not found`

**Symptom:**
```
bash: ros2: command not found
```

**Cause:** ROS 2 environment not sourced.

**Fix:**
```bash
source /opt/ros/humble/setup.bash

# Make it permanent inside the container:
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

---

## Error 2: No Serial Device Found

**Symptom:**
```
ls: cannot access '/dev/ttyUSB0': No such file or directory
```

**Diagnosis:**
```bash
# Check all tty devices
ls /dev/tty*

# Check kernel USB events
sudo dmesg | tail -30 | grep -E "tty|USB|usb"
```

**Fixes:**

1. **USB cable is charge-only** — swap for a data cable. Test: the file appears when you plug in.
2. **Missing driver:**
   ```bash
   sudo modprobe cp210x   # For CP2102 chip
   sudo modprobe ch341    # For CH340 chip
   ```
3. **`brltty` conflict** (Ubuntu 22.04):
   ```bash
   sudo apt remove brltty
   # Then unplug and replug the ESP32
   ```
4. **Permission denied:**
   ```bash
   sudo usermod -aG dialout $USER
   newgrp dialout
   ```

---

## Error 3: Agent Starts But No Topics Appear

**Symptom:** Agent running, but `ros2 topic list` shows nothing from ESP32.

**Diagnosis flow:**
```
Is ESP32 powered? ─NO─► Power it on
       │YES
Is firmware flashed? ─NO─► Flash firmware (idf.py flash)
       │YES
Is firmware running? ─NO─► Check idf.py monitor for errors
       │YES
Is correct port used? ─NO─► Check ls /dev/tty* and use that port
       │YES
Is USB cable a data cable? ─NO─► Swap cable
       │YES
→ Check Agent output for "Client connected" message
```

**Check Agent for connection:**
```
[1735047123.456] info     | TermiosAgentLinux.cpp | ...
[1735047125.789] info     | Root.cpp | create_client     ← ESP32 connected!
[1735047125.790] info     | Root.cpp | create_entities   ← Topics being created
```

If you see no `create_client`, the ESP32 is not reaching the Agent.

---

## Error 4: Only `/parameter_events` and `/rosout` Visible

**Symptom:**
```bash
ros2 topic list
# /parameter_events
# /rosout
```

**Cause:** ESP32 is not connected to the micro-ROS Agent.

**Checks:**
```bash
# 1. Is ESP32 physically connected?
ls /dev/ttyUSB0

# 2. Is firmware running? (monitor the ESP32)
# On laptop:
idf.py -p /dev/ttyUSB0 monitor

# 3. Is Agent using the correct port?
# The port you pass to the Agent must match the ESP32's port
ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0
#                                                            ^^^^^^ confirm this
```

---

## Error 5: Docker Container Not Running

**Symptom:**
```
Error response from daemon: Container ros2_humble is not running
```

**Fix:**
```bash
# List all containers (including stopped)
sudo docker ps -a

# Start the stopped container
sudo docker start ros2_humble

# Verify it's running
sudo docker ps | grep ros2_humble

# If it doesn't exist at all, recreate it:
sudo docker run -it \
  --name ros2_humble \
  --network host \
  --privileged \
  -v /dev:/dev \
  ros:humble bash
```

**Make container auto-start on boot:**
```bash
sudo docker update --restart unless-stopped ros2_humble
```

---

## Error 6: `Failed status on line X: Aborting`

**Symptom (ESP32 serial monitor):**
```
Failed status on line 42: 11. Aborting.
```

**Cause:** The micro-ROS API call on that line returned an error code.

**Most common cause:** The micro-ROS Agent is not running when the ESP32 boots.

**Fix:**
1. **Always start the Agent BEFORE powering the ESP32** (or before the firmware task runs)
2. Or add a retry loop:
   ```c
   // Wait for Agent connection with retries
   while (rclc_support_init(&support, 0, NULL, &allocator) != RCL_RET_OK) {
       printf("Waiting for micro-ROS Agent...\n");
       vTaskDelay(pdMS_TO_TICKS(1000));
   }
   ```

**Decode the error code:**

| Code | Meaning |
|------|---------|
| 1 | `RCL_RET_ERROR` — Generic error |
| 2 | `RCL_RET_TIMEOUT` — Transport timeout |
| 11 | `RCL_RET_NODE_INVALID` — Node not initialized |
| 14 | `RMW_RET_TIMEOUT` — DDS timeout |

---

## Error 7: Firmware Won't Flash

**Symptom:**
```
A fatal error occurred: Failed to connect to ESP32
```

**Fix — Enter flash mode manually:**
1. Hold the **BOOT** (IO0) button
2. Press and release **EN** (Reset)
3. Release **BOOT**
4. Run `idf.py -p /dev/ttyUSB0 flash`

**Or reduce flash speed:**
```bash
idf.py -p /dev/ttyUSB0 -b 115200 flash
```

**Check port permissions:**
```bash
sudo chmod 666 /dev/ttyUSB0
# Or permanently:
sudo usermod -aG dialout $USER
```

---

## Error 8: ESP32 Keeps Rebooting (Watchdog Reset)

**Symptom (monitor):**
```
Guru Meditation Error: Core 0 panic'ed (Task watchdog got triggered)
Backtrace: ...
ets Jun 8 2016 00:22:57
rst:0xc (SW_CPU_RESET),boot:0x13
```

**Causes and fixes:**

1. **Stack overflow** — Increase task stack:
   ```c
   // Change 16000 to 32000
   xTaskCreate(micro_ros_task, "micro_ros_task", 32000, NULL, 5, NULL);
   ```

2. **Blocking call inside executor** — Never call `vTaskDelay()` inside a callback. Use the executor's own timing.

3. **Too much work in callback** — Offload heavy processing to a queue.

---

## Error 9: Build Fails — Missing `rclc` Headers

**Symptom:**
```
fatal error: rclc/rclc.h: No such file or directory
```

**Fix:**

1. Check the micro-ROS component is in place:
   ```bash
   ls components/micro_ros_espidf_component/
   ```

2. If missing, clone it:
   ```bash
   mkdir -p components
   git clone https://github.com/micro-ROS/micro_ros_espidf_component.git \
     components/micro_ros_espidf_component
   ```

3. Clean and rebuild:
   ```bash
   idf.py fullclean
   idf.py build
   ```

---

## Error 10: micro-ROS Agent Exits Immediately

**Symptom:**
```bash
ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0
# Exits with no output
```

**Fixes:**

```bash
# 1. Check if the device exists
ls -l /dev/ttyUSB0

# 2. Check permissions
sudo chmod 666 /dev/ttyUSB0

# 3. Try with sudo
sudo docker exec -it ros2_humble bash -c \
  "source /opt/ros/humble/setup.bash && \
   ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0 -v6"

# -v6 = maximum verbosity — shows exactly what's failing
```

---

## Quick Reference Commands

```bash
# Check everything at once
ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null    # ESP32 detected?
sudo docker ps                               # Container running?
sudo dmesg | tail -10                        # Recent USB events

# Fix permissions
sudo usermod -aG dialout $USER
sudo chmod 666 /dev/ttyUSB0

# Start Agent
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash
ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0

# View topics
ros2 topic list
ros2 topic echo /encoder

# Reset ESP32 without unplugging
# (Use EN/Reset button on the board)
```

---

## Getting More Help

- [micro-ROS documentation](https://micro.ros.org/docs/overview/)
- [ESP-IDF error reference](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [ROS 2 CLI tools](https://docs.ros.org/en/humble/Tutorials/Beginner-CLI-Tools.html)
- [micro-ROS GitHub Issues](https://github.com/micro-ROS/micro_ros_arduino/issues)
