#!/bin/bash
# =============================================================================
# 05_publish_command.sh
# Step 7: Publish a command from ROS 2 to ESP32.
#
# Usage:
#   ./05_publish_command.sh [topic] [msg_type] [data]
#
# Examples:
#   ./05_publish_command.sh                          # Default: motor_cmd = 100
#   ./05_publish_command.sh /motor_cmd std_msgs/msg/Int32 "{data: 200}"
#   ./05_publish_command.sh /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}}"
# =============================================================================

CONTAINER_NAME="ros2_humble"

# ── Defaults ─────────────────────────────────────────────────────────────────
TOPIC="${1:-/motor_cmd}"
MSG_TYPE="${2:-std_msgs/msg/Int32}"
DATA="${3:-{data: 100}}"

echo "============================================="
echo "  Publishing Command to ESP32"
echo "  Topic   : $TOPIC"
echo "  Type    : $MSG_TYPE"
echo "  Data    : $DATA"
echo "  Container: $CONTAINER_NAME"
echo "============================================="
echo ""
echo "[INFO] Sending message (once)..."
echo ""

sudo docker exec -it "$CONTAINER_NAME" bash -c "
    source /opt/ros/humble/setup.bash && \
    ros2 topic pub --once '$TOPIC' '$MSG_TYPE' '$DATA'
"

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "[SUCCESS] Message published."
    echo "          The ESP32 should have received: $DATA"
else
    echo "[ERROR] Failed to publish message (exit code: $EXIT_CODE)."
    echo ""
    echo "  Check:"
    echo "  - Is the Agent running?      ./02_start_agent.sh"
    echo "  - Is the topic correct?      ./03_verify_topics.sh"
    echo "  - Is the message type valid? e.g. std_msgs/msg/Int32"
fi

echo ""
echo "============================================="
