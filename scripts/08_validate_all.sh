#!/bin/bash
# =============================================================================
# 08_validate_all.sh
# Full Validation Checklist (before proceeding to rover).
# Runs ALL checks in sequence and prints a pass/fail summary.
#
# Usage: ./08_validate_all.sh [serial_port]
#   Default serial port: /dev/ttyUSB0
# =============================================================================

CONTAINER_NAME="ros2_humble"
SERIAL_PORT="${1:-/dev/ttyUSB0}"

PASS=0
FAIL=0
RESULTS=()

echo ""
echo "╔═════════════════════════════════════════════╗"
echo "║      micro-ROS ESP32 Validation Checklist   ║"
echo "╚═════════════════════════════════════════════╝"
echo ""

# ── Helper functions ─────────────────────────────────────────────────────────

check() {
    local LABEL="$1"
    local RESULT="$2"   # 0=pass, 1=fail
    if [ "$RESULT" -eq 0 ]; then
        echo "  [✓] $LABEL"
        RESULTS+=("PASS: $LABEL")
        ((PASS++))
    else
        echo "  [✗] $LABEL"
        RESULTS+=("FAIL: $LABEL")
        ((FAIL++))
    fi
}

# ── CHECK 1: Docker running ──────────────────────────────────────────────────
echo "── Section 1: Infrastructure ────────────────────"
sudo docker ps &>/dev/null
check "Docker daemon is reachable" $?

# ── CHECK 2: Container exists and running ────────────────────────────────────
CONTAINER_RUNNING=$(sudo docker ps --format '{{.Names}}' | grep -c "^${CONTAINER_NAME}$")
[ "$CONTAINER_RUNNING" -gt 0 ]
check "ROS 2 container '$CONTAINER_NAME' is running" $?

# ── CHECK 3: ESP32 USB device exists ────────────────────────────────────────
echo ""
echo "── Section 2: Hardware ──────────────────────────"
ls /dev/ttyUSB* 1>/dev/null 2>&1 || ls /dev/ttyACM* 1>/dev/null 2>&1
check "ESP32 detected on USB ($SERIAL_PORT or ttyACM*)" $?

# ── CHECK 4: Serial port accessible ─────────────────────────────────────────
[ -e "$SERIAL_PORT" ]
check "Serial port '$SERIAL_PORT' exists" $?

# ── CHECK 5: ROS topics present ─────────────────────────────────────────────
echo ""
echo "── Section 3: ROS 2 Communication ──────────────"
TOPIC_LIST=$(sudo docker exec "$CONTAINER_NAME" bash -c \
    "source /opt/ros/humble/setup.bash && ros2 topic list 2>/dev/null")

echo "$TOPIC_LIST" | grep -q "^/parameter_events$"
check "ROS 2 is running (parameter_events visible)" $?

echo "$TOPIC_LIST" | grep -q "^/encoder$"
check "Publisher topic /encoder is visible" $?

echo "$TOPIC_LIST" | grep -q "^/imu$"
check "Publisher topic /imu is visible" $?

echo "$TOPIC_LIST" | grep -q "^/cmd_vel$"
check "Subscriber topic /cmd_vel is visible" $?

# ── CHECK 6: Nodes present ───────────────────────────────────────────────────
NODE_LIST=$(sudo docker exec "$CONTAINER_NAME" bash -c \
    "source /opt/ros/humble/setup.bash && ros2 node list 2>/dev/null")

echo "$NODE_LIST" | grep -q "^/micro_ros_agent$"
check "Node /micro_ros_agent is running" $?

echo "$NODE_LIST" | grep -q "^/esp32_node$"
check "Node /esp32_node is running" $?

# ── CHECK 7: Can receive data from ESP32 ─────────────────────────────────────
echo ""
echo "── Section 4: Data Flow ─────────────────────────"

# Try to receive one message from /encoder within 5 seconds
ENCODER_DATA=$(timeout 5 sudo docker exec "$CONTAINER_NAME" bash -c \
    "source /opt/ros/humble/setup.bash && ros2 topic echo /encoder --once 2>/dev/null")
[ -n "$ENCODER_DATA" ]
check "Received data from /encoder (ESP32 → Pi)" $?

# ── CHECK 8: Can publish to ESP32 ────────────────────────────────────────────
sudo docker exec "$CONTAINER_NAME" bash -c \
    "source /opt/ros/humble/setup.bash && \
     ros2 topic pub --once /motor_cmd std_msgs/msg/Int32 '{data: 0}' &>/dev/null"
check "Published command to ESP32 via /motor_cmd (Pi → ESP32)" $?

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "╔═════════════════════════════════════════════╗"
echo "║                  SUMMARY                   ║"
echo "╠═════════════════════════════════════════════╣"
printf "║  %-10s %-30s   ║\n" "PASSED:" "$PASS checks"
printf "║  %-10s %-30s   ║\n" "FAILED:" "$FAIL checks"
echo "╠═════════════════════════════════════════════╣"

TOTAL=$((PASS + FAIL))
if [ $FAIL -eq 0 ]; then
    echo "║  ✅ ALL $TOTAL CHECKS PASSED — Ready for rover!  ║"
else
    echo "║  ❌ $FAIL of $TOTAL checks FAILED — Fix before rover! ║"
fi
echo "╚═════════════════════════════════════════════╝"
echo ""

# Print failed items
if [ $FAIL -gt 0 ]; then
    echo "Failed checks:"
    for r in "${RESULTS[@]}"; do
        if [[ "$r" == FAIL:* ]]; then
            echo "  ✗ ${r#FAIL: }"
        fi
    done
    echo ""
    echo "Run individual scripts to fix:"
    echo "  ./02_start_agent.sh   — Start micro-ROS Agent"
    echo "  ./01_check_esp32.sh   — Check USB connection"
    echo "  ./03_verify_topics.sh — Check topics"
    echo ""
fi

exit $FAIL
