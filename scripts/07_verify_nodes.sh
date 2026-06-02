#!/bin/bash
# =============================================================================
# 07_verify_nodes.sh
# Step 9: Verify ROS 2 Nodes are running (ESP32 + micro-ROS Agent).
# =============================================================================

CONTAINER_NAME="ros2_humble"

EXPECTED_NODES=(
    "/esp32_node"
    "/micro_ros_agent"
)

echo "============================================="
echo "  Verifying ROS 2 Nodes"
echo "  Container: $CONTAINER_NAME"
echo "============================================="
echo ""

echo "[INFO] Fetching node list..."
echo ""

NODE_OUTPUT=$(sudo docker exec "$CONTAINER_NAME" bash -c \
    "source /opt/ros/humble/setup.bash && ros2 node list 2>&1")

if [ $? -ne 0 ]; then
    echo "[ERROR] Could not run ros2 node list."
    echo "        Is the container '$CONTAINER_NAME' running?"
    exit 1
fi

echo "  Nodes found:"
echo "  ─────────────────────────────────"
echo "$NODE_OUTPUT" | while read -r line; do
    echo "    $line"
done
echo "  ─────────────────────────────────"
echo ""

# ── Check expected nodes ─────────────────────────────────────────────────────
echo "[INFO] Checking for expected nodes..."
echo ""

ALL_OK=1
for node in "${EXPECTED_NODES[@]}"; do
    if echo "$NODE_OUTPUT" | grep -q "^${node}$"; then
        echo "  [OK]     $node"
    else
        echo "  [MISSING] $node"
        ALL_OK=0
    fi
done

echo ""
if [ $ALL_OK -eq 1 ]; then
    echo "[SUCCESS] All expected nodes are active!"
else
    echo "[WARN] Some nodes are missing."
    echo ""
    echo "  Checks:"
    echo "  - Is micro-ROS Agent running?  → ./02_start_agent.sh"
    echo "  - Is ESP32 connected & running firmware?"
    echo "  - Is the USB cable a data cable?"
fi

echo ""
echo "============================================="
