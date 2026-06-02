#!/bin/bash
# =============================================================================
# daily_workflow.sh
# One-script daily startup guide for micro-ROS ESP32 development.
#
# This script is INTERACTIVE — it walks you through each step,
# showing the command to run, then waits for your confirmation.
#
# Usage: ./daily_workflow.sh [PI_IP] [serial_port]
#   PI_IP       : IP address of the Raspberry Pi (optional, for reminders)
#   serial_port : Serial device for ESP32 (default: /dev/ttyUSB0)
#
# Run this ON the Raspberry Pi (either directly or via SSH).
# =============================================================================

PI_IP="${1:-<YOUR_PI_IP>}"
SERIAL_PORT="${2:-/dev/ttyUSB0}"
CONTAINER_NAME="ros2_humble"

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${CYAN}  $1${RESET}"; \
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }
step()    { echo -e "\n${BOLD}${YELLOW}[$1]${RESET} $2"; }
info()    { echo -e "  ${CYAN}→${RESET} $1"; }
ok()      { echo -e "  ${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "  ${YELLOW}[WARN]${RESET} $1"; }
err()     { echo -e "  ${RED}[ERROR]${RESET} $1"; }
pause()   { echo -e "\n  ${BOLD}Press ENTER to continue, or Ctrl+C to exit...${RESET}"; read -r; }

# ═════════════════════════════════════════════════════════════════════════════
header "micro-ROS ESP32 Daily Workflow"
echo "  Pi IP      : $PI_IP"
echo "  Serial port: $SERIAL_PORT"
echo "  Container  : $CONTAINER_NAME"
echo ""
echo "  This script guides you step-by-step."
echo "  Run it ON the Raspberry Pi."
pause

# ─────────────────────────────────────────────────────────────────────────────
step "1/7" "Check Docker container"
info "Command: sudo docker ps -a"
echo ""
sudo docker ps -a
echo ""

# Auto-start container if not running
if ! sudo docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    warn "Container '$CONTAINER_NAME' is not running. Starting it..."
    sudo docker start "$CONTAINER_NAME" && ok "Container started." || \
        { err "Failed to start container. Exiting."; exit 1; }
else
    ok "Container '$CONTAINER_NAME' is running."
fi
pause

# ─────────────────────────────────────────────────────────────────────────────
step "2/7" "Verify ESP32 USB Connection"
info "Command: ls /dev/tty*"
echo ""
ls /dev/tty* 2>/dev/null
echo ""

if ls /dev/ttyUSB* 1>/dev/null 2>&1 || ls /dev/ttyACM* 1>/dev/null 2>&1; then
    ok "ESP32 serial device detected."
else
    warn "No ESP32 device found at ttyUSB* or ttyACM*."
    echo "  → Check USB cable. Try 01_check_esp32.sh for details."
fi
pause

# ─────────────────────────────────────────────────────────────────────────────
step "3/7" "Start micro-ROS Agent (runs in background)"
info "Command: sudo docker exec -it $CONTAINER_NAME bash -c \\"
info "         \"source /opt/ros/humble/setup.bash && \\"
info "          ros2 run micro_ros_agent micro_ros_agent serial --dev $SERIAL_PORT\""
echo ""
echo -e "  ${YELLOW}The Agent will be launched in a background tmux/subshell.${RESET}"
echo -e "  ${YELLOW}If you don't have tmux, open a SECOND terminal for the Agent.${RESET}"
echo ""

if command -v tmux &>/dev/null; then
    # Launch Agent in a new tmux window
    tmux new-window -n "micro_ros_agent" \
        "sudo docker exec -it $CONTAINER_NAME bash -c \
         'source /opt/ros/humble/setup.bash && \
          ros2 run micro_ros_agent micro_ros_agent serial --dev $SERIAL_PORT'" 2>/dev/null && \
        ok "Agent launched in tmux window 'micro_ros_agent'." || \
        warn "tmux launch failed — please start Agent manually in another terminal."
else
    warn "tmux not found. Starting Agent in background (output suppressed)."
    sudo docker exec "$CONTAINER_NAME" bash -c \
        "source /opt/ros/humble/setup.bash && \
         ros2 run micro_ros_agent micro_ros_agent serial --dev $SERIAL_PORT" \
        > /tmp/micro_ros_agent.log 2>&1 &
    AGENT_PID=$!
    sleep 3
    if kill -0 $AGENT_PID 2>/dev/null; then
        ok "Agent running (PID: $AGENT_PID). Log: /tmp/micro_ros_agent.log"
    else
        err "Agent exited immediately. Check /tmp/micro_ros_agent.log"
    fi
fi
pause

# ─────────────────────────────────────────────────────────────────────────────
step "4/7" "Verify ROS 2 Topics"
info "Command: ros2 topic list"
echo ""

sleep 2  # Allow Agent to initialize
TOPIC_LIST=$(sudo docker exec "$CONTAINER_NAME" bash -c \
    "source /opt/ros/humble/setup.bash && ros2 topic list 2>/dev/null")

echo "$TOPIC_LIST"
echo ""

for t in "/encoder" "/imu" "/cmd_vel"; do
    if echo "$TOPIC_LIST" | grep -q "^${t}$"; then
        ok "Topic $t visible"
    else
        warn "Topic $t NOT visible (ESP32 may not be publishing yet)"
    fi
done
pause

# ─────────────────────────────────────────────────────────────────────────────
step "5/7" "View Data from ESP32 (/encoder)"
info "Command: ros2 topic echo /encoder"
echo ""
echo -e "  ${YELLOW}Listening for 3 messages then continuing...${RESET}"
echo ""

timeout 8 sudo docker exec "$CONTAINER_NAME" bash -c \
    "source /opt/ros/humble/setup.bash && ros2 topic echo /encoder" 2>/dev/null \
    | head -15 || warn "No data received on /encoder within timeout."
pause

# ─────────────────────────────────────────────────────────────────────────────
step "6/7" "Verify Nodes"
info "Command: ros2 node list"
echo ""

NODE_LIST=$(sudo docker exec "$CONTAINER_NAME" bash -c \
    "source /opt/ros/humble/setup.bash && ros2 node list 2>/dev/null")

echo "$NODE_LIST"
echo ""

for n in "/esp32_node" "/micro_ros_agent"; do
    if echo "$NODE_LIST" | grep -q "^${n}$"; then
        ok "Node $n is active"
    else
        warn "Node $n is NOT visible"
    fi
done
pause

# ─────────────────────────────────────────────────────────────────────────────
step "7/7" "Test: Publish Command to ESP32"
info "Command: ros2 topic pub --once /motor_cmd std_msgs/msg/Int32 '{data: 100}'"
echo ""

sudo docker exec "$CONTAINER_NAME" bash -c \
    "source /opt/ros/humble/setup.bash && \
     ros2 topic pub --once /motor_cmd std_msgs/msg/Int32 '{data: 100}'"
echo ""
ok "Command sent. ESP32 should have received: 100"

# ─────────────────────────────────────────────────────────────────────────────
header "Daily Workflow Complete!"
echo ""
echo -e "  ${GREEN}Useful scripts you can run next:${RESET}"
echo "  ./04_view_data.sh /imu         — View IMU data"
echo "  ./05_publish_command.sh        — Send custom commands"
echo "  ./06_test_led.sh blink         — Test LED blink"
echo "  ./08_validate_all.sh           — Full validation checklist"
echo ""
