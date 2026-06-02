# micro-ROS ESP32 Scripts

Shell scripts for every step of the micro-ROS ESP32 workflow.

---

## Prerequisites

These scripts run **on the Raspberry Pi** (directly or via SSH from Windows/Ubuntu).

---

## First-Time Setup (from Laptop)

Copy scripts to your Pi:

```bash
# From your laptop (Git Bash on Windows or Ubuntu terminal)
./deploy_to_pi.sh <PI_IP>

# Example
./deploy_to_pi.sh 192.168.1.42
```

SSH into the Pi and make scripts executable:

```bash
ssh aadi_1234@<PI_IP>
cd ~/micro_ros_esp32/scripts
chmod +x *.sh
```

---

## Scripts Reference

| Script | Step | Description |
|--------|------|-------------|
| `01_check_esp32.sh` | Step 3 | Detect ESP32 USB serial device |
| `02_start_agent.sh` | Step 4 | Start micro-ROS Agent in Docker |
| `03_verify_topics.sh` | Steps 5 & 10 | List and validate ROS 2 topics |
| `04_view_data.sh` | Step 6 | Echo live data from any topic |
| `05_publish_command.sh` | Step 7 | Publish a command to ESP32 |
| `06_test_led.sh` | Step 8 | Test LED blink via `/led_cmd` |
| `07_verify_nodes.sh` | Step 9 | Verify ESP32 + Agent nodes |
| `08_validate_all.sh` | Checklist | Full pass/fail validation |
| `daily_workflow.sh` | Daily | Interactive step-by-step guide |
| `ssh_into_pi.sh` | Windows | SSH + run remote scripts from laptop |
| `deploy_to_pi.sh` | Setup | Copy scripts to Pi via SCP |

---

## Daily Workflow (Quick Start)

```bash
# On the Raspberry Pi
./daily_workflow.sh

# With custom serial port
./daily_workflow.sh 192.168.1.42 /dev/ttyACM0
```

---

## Individual Commands

```bash
# Check ESP32 USB
./01_check_esp32.sh

# Start Agent (default: /dev/ttyUSB0)
./02_start_agent.sh
./02_start_agent.sh /dev/ttyACM0    # Override port

# Verify topics
./03_verify_topics.sh

# View encoder data
./04_view_data.sh
./04_view_data.sh /imu              # View IMU topic
./04_view_data.sh /encoder 10       # Read 10 messages

# Publish motor command
./05_publish_command.sh
./05_publish_command.sh /motor_cmd std_msgs/msg/Int32 "{data: 200}"

# Test LED
./06_test_led.sh blink              # Blink 5 times
./06_test_led.sh on                 # Turn ON
./06_test_led.sh off                # Turn OFF

# Verify nodes
./07_verify_nodes.sh

# Full validation (before rover)
./08_validate_all.sh
```

---

## From Windows (SSH Helper)

```bash
# Open interactive session
./ssh_into_pi.sh 192.168.1.42

# Run specific step remotely
./ssh_into_pi.sh 192.168.1.42 check      # Check ESP32
./ssh_into_pi.sh 192.168.1.42 agent      # Start Agent
./ssh_into_pi.sh 192.168.1.42 topics     # Verify topics
./ssh_into_pi.sh 192.168.1.42 nodes      # Verify nodes
./ssh_into_pi.sh 192.168.1.42 validate   # Full validation
./ssh_into_pi.sh 192.168.1.42 workflow   # Daily workflow
```

---

## Common Errors

| Error | Fix |
|-------|-----|
| `ros2: command not found` | `source /opt/ros/humble/setup.bash` |
| No serial device | Check USB cable (data, not charge-only) |
| Agent starts, no topics | ESP32 powered? Firmware running? Correct port? |
| Only `/parameter_events` visible | ESP32 not connected to Agent |
| Container not running | `sudo docker start ros2_humble` |

---

## Validation Checklist

Before moving to rover development, run `./08_validate_all.sh` and confirm:

- ✓ ROS 2 container running
- ✓ micro-ROS Agent running  
- ✓ ESP32 detected on USB
- ✓ Topics visible (`/encoder`, `/imu`, `/cmd_vel`)
- ✓ Publisher working (data received via `echo`)
- ✓ Subscriber working (commands reach ESP32)
