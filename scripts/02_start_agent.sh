#!/bin/bash
# =============================================================================
# 02_start_agent.sh
# Step 4: Start the micro-ROS Agent inside the ROS 2 Docker container.
# Run this on the Raspberry Pi (via SSH or directly).
#
# Usage:
#   ./02_start_agent.sh [serial_port]
#
#   Default port: /dev/ttyUSB0
#   Override:     ./02_start_agent.sh /dev/ttyACM0
# =============================================================================

CONTAINER_NAME="ros2_humble"
SERIAL_PORT="${1:-/dev/ttyUSB0}"    # Use argument or default to /dev/ttyUSB0

echo "============================================="
echo "  Starting micro-ROS Agent"
echo "  Container : $CONTAINER_NAME"
echo "  Serial Dev: $SERIAL_PORT"
echo "============================================="
echo ""

# ── Step 1: Check Docker is running ──────────────────────────────────────────
echo "[1/4] Checking Docker service..."
if ! command -v docker &>/dev/null; then
    echo "[ERROR] Docker is not installed or not on PATH."
    exit 1
fi

if ! sudo docker ps &>/dev/null; then
    echo "[ERROR] Cannot reach Docker daemon. Try: sudo systemctl start docker"
    exit 1
fi
echo "[OK]  Docker is running."
echo ""

# ── Step 2: Ensure the container exists ─────────────────────────────────────
echo "[2/4] Checking container '$CONTAINER_NAME'..."
if ! sudo docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "[ERROR] Container '$CONTAINER_NAME' does not exist."
    echo "        Run: sudo docker ps -a   to list all containers."
    exit 1
fi
echo "[OK]  Container found."
echo ""

# ── Step 3: Start container if not already running ──────────────────────────
echo "[3/4] Starting container if stopped..."
if ! sudo docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "[INFO] Container is stopped. Starting it..."
    sudo docker start "$CONTAINER_NAME"
    sleep 2
fi
echo "[OK]  Container is running."
echo ""

# ── Step 4: Check the serial port exists ────────────────────────────────────
echo "[4/4] Checking serial port '$SERIAL_PORT'..."
if [ ! -e "$SERIAL_PORT" ]; then
    echo "[WARN] '$SERIAL_PORT' not found. Run 01_check_esp32.sh to find the correct port."
    echo "       Continuing anyway — Docker may map the device differently."
fi
echo ""

# ── Launch the micro-ROS Agent ───────────────────────────────────────────────
echo "============================================="
echo "  Launching micro-ROS Agent..."
echo "  Press Ctrl+C to stop."
echo "============================================="
echo ""

sudo docker exec -it "$CONTAINER_NAME" bash -c "
    source /opt/ros/humble/setup.bash && \
    echo '[AGENT] ROS 2 sourced. Starting micro-ROS Agent on $SERIAL_PORT ...' && \
    ros2 run micro_ros_agent micro_ros_agent serial --dev $SERIAL_PORT
"

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -ne 0 ]; then
    echo "[ERROR] micro-ROS Agent exited with code $EXIT_CODE."
    echo ""
    echo "  Common causes:"
    echo "  - Wrong serial port. Try /dev/ttyACM0 instead of /dev/ttyUSB0."
    echo "  - ESP32 not powered or firmware not running."
    echo "  - USB cable is charge-only."
fi
