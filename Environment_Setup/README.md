# Environment Setup

> Install and verify all software required to run micro-ROS on ESP32 with ROS 2 Humble.

---

## Overview

This module sets up the complete software stack:

```
Laptop                 Raspberry Pi              ESP32
──────                 ────────────              ─────
ESP-IDF          →     ROS 2 Humble (Docker)  →  micro-ROS firmware
micro-ROS tools        micro-ROS Agent            (flashed from laptop)
```

---

## Step 1 — Raspberry Pi: Install Docker

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Allow current user to run docker without sudo (optional)
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version
```

---

## Step 2 — Raspberry Pi: Pull ROS 2 Humble Docker Image

```bash
# Pull the official ROS 2 Humble image
sudo docker pull ros:humble

# Create and name the container
sudo docker run -it \
  --name ros2_humble \
  --network host \
  --privileged \
  -v /dev:/dev \
  ros:humble \
  bash

# Verify ROS 2 inside container
source /opt/ros/humble/setup.bash
ros2 --version
```

> **Note:** `--privileged` and `-v /dev:/dev` are required so the container can access the USB serial device (`/dev/ttyUSB0`).

---

## Step 3 — Raspberry Pi: Install micro-ROS Agent (inside Docker)

```bash
# Enter the container
sudo docker exec -it ros2_humble bash

# Inside container — install micro-ROS tools
source /opt/ros/humble/setup.bash

apt update && apt install -y python3-pip

pip3 install vcstool

mkdir -p /microros_ws/src
cd /microros_ws

# Download and build micro-ROS Agent
git clone -b humble https://github.com/micro-ROS/micro_ros_setup.git src/micro_ros_setup

rosdep update
rosdep install --from-paths src --ignore-src -y

colcon build

source install/setup.bash

# Create and build the agent
ros2 run micro_ros_setup create_agent_ws.sh
ros2 run micro_ros_setup build_agent.sh

# Verify
ros2 run micro_ros_agent micro_ros_agent --help
```

---

## Step 4 — Laptop: Install ESP-IDF

```bash
# Prerequisites (Ubuntu)
sudo apt install -y git wget flex bison gperf python3 \
  python3-pip python3-setuptools cmake ninja-build ccache \
  libffi-dev libssl-dev dfu-util libusb-1.0-0

# Clone ESP-IDF (use v5.x for best micro-ROS compatibility)
mkdir -p ~/esp
cd ~/esp
git clone --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
git checkout v5.1.2
git submodule update --init --recursive

# Run installer
./install.sh esp32

# Add to shell (add to ~/.bashrc for persistence)
. $HOME/esp/esp-idf/export.sh

# Verify
idf.py --version
```

---

## Step 5 — Laptop: Set Up micro-ROS for ESP-IDF

```bash
# Create your ESP-IDF project directory
mkdir -p ~/esp/micro_ros_project
cd ~/esp/micro_ros_project

# Clone the micro-ROS ESP-IDF component
git clone https://github.com/micro-ROS/micro_ros_espidf_component.git \
  components/micro_ros_espidf_component

# Source ESP-IDF
. $HOME/esp/esp-idf/export.sh

# Set target
idf.py set-target esp32
```

---

## Step 6 — Verify Full Environment

### On Raspberry Pi:
```bash
# Docker running?
sudo docker ps

# Container running?
sudo docker ps -a | grep ros2_humble

# Start if stopped
sudo docker start ros2_humble

# micro-ROS Agent available?
sudo docker exec ros2_humble bash -c \
  "source /opt/ros/humble/setup.bash && \
   ros2 run micro_ros_agent micro_ros_agent --help"
```

### On Laptop:
```bash
# ESP-IDF available?
idf.py --version

# Python tools?
python3 --version
pip3 list | grep esptool
```

---

## Environment Checklist

| Item | Command | Expected Output |
|------|---------|----------------|
| Docker | `docker --version` | `Docker version 24.x` |
| ROS 2 container | `sudo docker ps` | `ros2_humble` listed |
| ROS 2 inside container | `ros2 --version` | `ros2 humble` |
| micro-ROS Agent | `ros2 run micro_ros_agent ... --help` | Help text printed |
| ESP-IDF | `idf.py --version` | `ESP-IDF v5.x` |

---

## Common Issues

| Problem | Fix |
|---------|-----|
| `docker: command not found` | Run the Docker install script again |
| Container won't start | `sudo docker start ros2_humble` |
| `ros2: command not found` inside container | `source /opt/ros/humble/setup.bash` |
| ESP-IDF not found | `source ~/esp/esp-idf/export.sh` |
| Python missing in container | `apt install -y python3-pip` |

---

## Next Step

→ [Hardware Setup](../Hardware_Setup/README.md)
