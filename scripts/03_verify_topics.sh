#!/bin/bash
# =============================================================================
# 03_verify_topics.sh
# Step 5 & 10: Verify ROS Topics visible from the micro-ROS Agent.
# Open a NEW terminal (separate from the Agent terminal) and run this.
# =============================================================================

CONTAINER_NAME="ros2_humble"

EXPECTED_TOPICS=(
    "/encoder"
    "/imu"
    "/cmd_vel"
    "/parameter_events"
    "/rosout"
)

echo "============================================="
echo "  Verifying ROS 2 Topics"
echo "  Container: $CONTAINER_NAME"
echo "============================================="
echo ""

# ── Get topic list from inside the container ─────────────────────────────────
echo "[INFO] Fetching topic list..."
echo ""

TOPIC_OUTPUT=$(sudo docker exec "$CONTAINER_NAME" bash -c \
    "source /opt/ros/humble/setup.bash && ros2 topic list 2>&1")

if [ $? -ne 0 ]; then
    echo "[ERROR] Could not run ros2 topic list inside container."
    echo "        Is the container '$CONTAINER_NAME' running?"
    echo "        Run: sudo docker ps"
    exit 1
fi

echo "  Topics found:"
echo "  ─────────────────────────────────"
echo "$TOPIC_OUTPUT" | while read -r line; do
    echo "    $line"
done
echo "  ─────────────────────────────────"
echo ""

# ── Check for expected topics ────────────────────────────────────────────────
echo "[INFO] Checking for expected topics..."
echo ""

ALL_OK=1
for topic in "${EXPECTED_TOPICS[@]}"; do
    if echo "$TOPIC_OUTPUT" | grep -q "^${topic}$"; then
        echo "  [OK]     $topic"
    else
        echo "  [MISSING] $topic"
        ALL_OK=0
    fi
done

echo ""

# ── Diagnosis ────────────────────────────────────────────────────────────────
if echo "$TOPIC_OUTPUT" | grep -qE "^/parameter_events$|^/rosout$"; then
    if [ $ALL_OK -eq 0 ]; then
        echo "[WARN] ROS 2 is running but ESP32 topics are missing."
        echo ""
        echo "  Possible reasons:"
        echo "  - micro-ROS Agent not started → run 02_start_agent.sh"
        echo "  - ESP32 not connected or firmware not running"
        echo "  - Wrong serial port used for the Agent"
        echo "  - USB cable is charge-only"
    else
        echo "[SUCCESS] All expected topics are visible!"
    fi
else
    echo "[ERROR] ROS 2 base topics not visible."
    echo "        Source ROS before checking: source /opt/ros/humble/setup.bash"
fi

echo ""
echo "============================================="
