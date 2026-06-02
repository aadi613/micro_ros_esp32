#!/bin/bash
# =============================================================================
# 04_view_data.sh
# Step 6: View live data published by ESP32 over a ROS 2 topic.
#
# Usage:
#   ./04_view_data.sh [topic] [count]
#
#   topic  : ROS 2 topic to echo  (default: /encoder)
#   count  : Number of messages   (default: continuous, Ctrl+C to stop)
#
# Examples:
#   ./04_view_data.sh                    # Echo /encoder continuously
#   ./04_view_data.sh /imu               # Echo /imu continuously
#   ./04_view_data.sh /encoder 10        # Echo 10 messages then exit
# =============================================================================

CONTAINER_NAME="ros2_humble"
TOPIC="${1:-/encoder}"
COUNT="${2:-}"   # Empty = continuous

echo "============================================="
echo "  Viewing ROS 2 Topic Data"
echo "  Topic    : $TOPIC"
echo "  Count    : ${COUNT:-continuous (Ctrl+C to stop)}"
echo "  Container: $CONTAINER_NAME"
echo "============================================="
echo ""

# ── Build the echo command ───────────────────────────────────────────────────
if [ -n "$COUNT" ]; then
    ECHO_CMD="ros2 topic echo $TOPIC --once"
    # For a specific count, loop
    ECHO_CMD="ros2 topic echo $TOPIC -n $COUNT 2>/dev/null || ros2 topic echo $TOPIC --once"
fi

ECHO_CMD="ros2 topic echo $TOPIC"
if [ -n "$COUNT" ]; then
    ECHO_CMD="ros2 topic echo $TOPIC --once"
    echo "[INFO] Waiting for $COUNT message(s) on $TOPIC ..."
    echo ""
    for i in $(seq 1 "$COUNT"); do
        sudo docker exec "$CONTAINER_NAME" bash -c \
            "source /opt/ros/humble/setup.bash && ros2 topic echo $TOPIC --once 2>/dev/null"
        echo "---"
    done
else
    echo "[INFO] Streaming data from $TOPIC ..."
    echo "       Press Ctrl+C to stop."
    echo ""
    sudo docker exec -it "$CONTAINER_NAME" bash -c \
        "source /opt/ros/humble/setup.bash && ros2 topic echo $TOPIC"
fi

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -ne 0 ]; then
    echo "[ERROR] Could not echo topic '$TOPIC'."
    echo ""
    echo "  Check:"
    echo "  1. Is the topic available?  Run: ./03_verify_topics.sh"
    echo "  2. Is the micro-ROS Agent running?  Run: ./02_start_agent.sh"
    echo "  3. Is the ESP32 powered and running firmware?"
fi
