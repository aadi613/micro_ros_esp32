#!/bin/bash
# =============================================================================
# 06_test_led.sh
# Step 8: Test LED Blink Demo — control the ESP32 onboard LED via ROS 2.
#
# Usage:
#   ./06_test_led.sh [on|off|blink]
#
#   on    → Send true  (LED ON)
#   off   → Send false (LED OFF)
#   blink → Toggle ON/OFF with a 1-second delay, repeat 5 times
#
# Default: blink
# =============================================================================

CONTAINER_NAME="ros2_humble"
TOPIC="/led_cmd"
MSG_TYPE="std_msgs/msg/Bool"
MODE="${1:-blink}"

echo "============================================="
echo "  LED Blink Demo"
echo "  Topic : $TOPIC"
echo "  Mode  : $MODE"
echo "============================================="
echo ""

# Helper: publish a single Bool message
publish_bool() {
    local VALUE="$1"    # true | false
    local LABEL="$2"    # ON | OFF
    echo "[ACTION] LED $LABEL  → Publishing: {data: $VALUE}"
    sudo docker exec "$CONTAINER_NAME" bash -c "
        source /opt/ros/humble/setup.bash && \
        ros2 topic pub --once '$TOPIC' '$MSG_TYPE' '{data: $VALUE}' 2>&1 | tail -1
    "
    echo ""
}

# ── Mode selection ────────────────────────────────────────────────────────────
case "$MODE" in
    on)
        publish_bool "true" "ON"
        echo "[EXPECTED] LED is ON"
        ;;

    off)
        publish_bool "false" "OFF"
        echo "[EXPECTED] LED is OFF"
        ;;

    blink)
        BLINK_COUNT=5
        echo "[INFO] Blinking LED $BLINK_COUNT times (1 sec interval)..."
        echo "       Press Ctrl+C to stop early."
        echo ""
        for i in $(seq 1 $BLINK_COUNT); do
            echo "  ── Blink $i ──"
            publish_bool "true"  "ON"
            sleep 1
            publish_bool "false" "OFF"
            sleep 1
        done
        echo "[DONE] Blink sequence complete. LED is OFF."
        ;;

    *)
        echo "[ERROR] Unknown mode: '$MODE'"
        echo "        Usage: ./06_test_led.sh [on|off|blink]"
        exit 1
        ;;
esac

echo ""
echo "============================================="
