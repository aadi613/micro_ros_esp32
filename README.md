# micro-ROS on ESP32 🤖

> **Learning micro-ROS on ESP32 with ROS 2 Humble** — from basic publisher/subscriber to PWM hardware control, all communicating over a Raspberry Pi bridge.

---

## 🧭 What This Repository Is

This repo documents a step-by-step learning journey of integrating **micro-ROS** on an **ESP32** microcontroller with **ROS 2 Humble** running on a **Raspberry Pi**. It is structured as a progressive series of modules, each building on the last.

---

## 🏗️ System Architecture

```
┌──────────────────────────────────────────────────┐
│                    Laptop                        │
│         (Windows / Ubuntu — SSH client)          │
└────────────────────┬─────────────────────────────┘
                     │ SSH
                     ▼
┌──────────────────────────────────────────────────┐
│               Raspberry Pi                       │
│  ┌─────────────────────────────────────────────┐ │
│  │     Docker Container: ros2_humble           │ │
│  │  ├── ROS 2 Humble                           │ │
│  │  └── micro-ROS Agent (serial transport)     │ │
│  └──────────────────┬──────────────────────────┘ │
└─────────────────────┼────────────────────────────┘
                      │ USB Serial (/dev/ttyUSB0)
                      ▼
┌──────────────────────────────────────────────────┐
│                  ESP32                           │
│  ├── micro-ROS Client (rclc)                    │
│  ├── Publisher  → sends Int32 data to ROS 2     │
│  ├── Subscriber ← receives Int32 from ROS 2     │
│  └── PWM Output → controls LED brightness       │
└──────────────────────────────────────────────────┘
```

---

## 📚 Learning Path & Video Tutorial Procedure

This repository follows the concepts from the **RoboFuntastic** YouTube playlist: [Esp32 with micro ROS tutorial](https://www.youtube.com/playlist?list=PL1YH3iMfizDJge1nDCuEMvCvhBkKinIJ-).

*(Note: The environment and hardware setup modules (1 & 2) cover the prerequisites. Below is the direct procedure from the first 3 videos, skipping installation).*

### Video 1: Int Publisher (Part 01)
**Goal:** Make the ESP32 publish a simple integer counter.
*Our Adaptation:* The tutorial uses Wi-Fi/native Ubuntu, but we use **Serial over USB via Docker on a Raspberry Pi**.
1. **Flash Firmware:** From your laptop (ESP-IDF), flash [`ESP32_Publisher/app.c`](ESP32_Publisher/app.c) via USB: `idf.py -p /dev/ttyUSB0 flash monitor`.
2. **Start Agent:** SSH into the Raspberry Pi, enter the Docker container, and start the agent on the serial port:
   ```bash
   sudo docker exec -it ros2_humble bash
   source /opt/ros/humble/setup.bash
   ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0
   ```
3. **Verify Data:** Open a second SSH session to the Pi, enter Docker, and check the topic:
   ```bash
   ros2 topic echo /esp32_publisher
   ```

### Video 2: Int32 Subscriber & Hardware Interface (Part 02)
**Goal:** Make the ESP32 receive an integer from ROS 2 to trigger a hardware action.
*Our Adaptation:* We handle the subscriber callback by printing the received value to the ESP32 serial monitor, avoiding complex hardware setups for now.
1. **Flash Firmware:** Flash [`ESP32_Subscriber/app.c`](ESP32_Subscriber/app.c) and leave the serial monitor running (`idf.py monitor`).
2. **Start Agent:** Same as Video 1, start the serial agent on the Pi.
3. **Send Command:** From a second Pi terminal (inside Docker), publish a command:
   ```bash
   ros2 topic pub --once /esp32_subscriber std_msgs/msg/Int32 "{data: 42}"
   ```
4. **Verify Output:** Watch the ESP-IDF serial monitor on your laptop; it should print `Received: 42`.

### Video 3: Publisher & Subscriber Bidirectional (Part 03)
**Goal:** Combine publishing sensor data and subscribing to control commands simultaneously.
*Our Adaptation:* We use `rclc_executor_init` with exactly `2` handles (1 timer + 1 subscriber) to prevent FreeRTOS crashes.
1. **Flash Firmware:** Flash [`ROS2_to_ESP32_Communication/app.c`](ROS2_to_ESP32_Communication/app.c).
2. **Start Agent:** Run the agent on the Pi as before.
3. **Test Bidirectional Flow:**
   - Terminal A (Pi): `ros2 topic echo /sensor_data` (should print incrementing integers).
   - Terminal B (Pi): `ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}, angular: {z: 0.0}}"`
   - Terminal C (Laptop): Watch the ESP-IDF monitor print both the published values and the received velocity command.

---

## 📁 Repository Structure

```
micro_ros_esp32/
│
├── README.md                        ← You are here
│
├── Environment_Setup/
│   └── README.md                    ← ROS 2, micro-ROS, ESP-IDF install guide
│
├── Hardware_Setup/
│   └── README.md                    ← ESP32 wiring, USB serial, USB IDs
│
├── ESP32_Publisher/
│   ├── app.c                        ← Publisher source (Int32 counter, 1 Hz)
│   └── README.md                    ← How to build, flash, and verify
│
├── ESP32_Subscriber/
│   ├── app.c                        ← Subscriber source (receives Int32)
│   └── README.md                    ← How to build, flash, and test
│
├── ROS2_to_ESP32_Communication/
│   └── README.md                    ← Combined pub+sub, bidirectional guide
│
├── PWM_LED_Control/
│   ├── app.c                        ← PWM source (LEDC, GPIO 2, 5 kHz)
│   ├── pwm_high_brightness.jpeg     ← Demo photo
│   ├── pwm_low_brightness.jpeg      ← Demo photo
│   ├── pwm_terminal.png             ← Terminal output screenshot
│   └── README.md                    ← PWM setup and topic publishing guide
│
├── Troubleshooting/
│   └── README.md                    ← Common errors and fixes
│
├── docs/
│   ├── architecture_overview.md     ← System diagram and data flow
│   ├── micro_ros_cheat_sheet.md     ← Quick-reference commands
│   └── useful_links.md              ← Official docs and references
│
└── scripts/                         ← Shell automation scripts
    ├── 01_check_esp32.sh
    ├── 02_start_agent.sh
    ├── 03_verify_topics.sh
    ├── 04_view_data.sh
    ├── 05_publish_command.sh
    ├── 06_test_led.sh
    ├── 07_verify_nodes.sh
    ├── 08_validate_all.sh
    ├── daily_workflow.sh
    ├── deploy_to_pi.sh
    └── ssh_into_pi.sh
```

---

## ⚡ Quick Start (Daily Workflow)

### 1. SSH into Raspberry Pi
```bash
ssh aadi_1234@<PI_IP>
```

### 2. Start the micro-ROS Agent
```bash
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash
ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0
```

### 3. Verify (new terminal)
```bash
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash
ros2 topic list          # Should show /encoder, /imu, /cmd_vel etc.
ros2 topic echo /encoder # View live ESP32 data
```

Or use the automation scripts:
```bash
cd ~/micro_ros_esp32/scripts
./daily_workflow.sh      # Interactive step-by-step
./08_validate_all.sh     # Full checklist
```

---

## 🔧 Tech Stack

| Layer | Technology |
|-------|-----------|
| Microcontroller | ESP32 (Xtensa LX6, dual-core, 240 MHz) |
| RTOS | FreeRTOS (via ESP-IDF) |
| micro-ROS layer | `rclc` / `rcl` (C API) |
| ROS version | ROS 2 Humble Hawksbill |
| Agent host | Raspberry Pi (in Docker) |
| Transport | USB Serial (UART) |
| Message types | `std_msgs/msg/Int32`, `std_msgs/msg/Bool` |
| Language | C |
| Build system | ESP-IDF (CMake) |

---

## 📋 Prerequisites

### Hardware
- ESP32 development board
- Raspberry Pi (any model with USB)
- USB cable (must support **data**, not charge-only)
- Laptop (Windows or Ubuntu)
- *(Future)* Motor Driver, Encoders, IMU

### Software
- ROS 2 Humble on Raspberry Pi (inside Docker)
- Docker container: `ros2_humble`
- micro-ROS Agent installed in the container
- ESP-IDF + micro-ROS firmware toolchain
- micro-ROS firmware already flashed on ESP32

---

## 🗺️ Topics Used

| Topic | Direction | Type | Description |
|-------|-----------|------|-------------|
| `/encoder` | ESP32 → ROS 2 | `std_msgs/Int32` | Encoder counter value |
| `/imu` | ESP32 → ROS 2 | `sensor_msgs/Imu` | IMU orientation data |
| `/cmd_vel` | ROS 2 → ESP32 | `geometry_msgs/Twist` | Velocity commands |
| `/motor_cmd` | ROS 2 → ESP32 | `std_msgs/Int32` | Motor speed command |
| `/led_cmd` | ROS 2 → ESP32 | `std_msgs/Bool` | LED on/off toggle |

---

## 🔗 Related Docs

- [`docs/architecture_overview.md`](docs/architecture_overview.md) — System diagram
- [`docs/micro_ros_cheat_sheet.md`](docs/micro_ros_cheat_sheet.md) — Quick commands
- [`docs/useful_links.md`](docs/useful_links.md) — Official references
- [`Troubleshooting/README.md`](Troubleshooting/README.md) — Fix common errors

---

## 👤 Author

**aadi613** — Learning robotics with ROS 2 + micro-ROS on ESP32.
