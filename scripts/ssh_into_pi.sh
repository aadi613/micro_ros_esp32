#!/bin/bash
# =============================================================================
# ssh_into_pi.sh
# Quick helper to SSH into the Raspberry Pi and optionally run a script.
#
# Usage:
#   ./ssh_into_pi.sh <PI_IP>               — Open interactive SSH session
#   ./ssh_into_pi.sh <PI_IP> check         — Run 01_check_esp32.sh on Pi
#   ./ssh_into_pi.sh <PI_IP> agent         — Run 02_start_agent.sh on Pi
#   ./ssh_into_pi.sh <PI_IP> topics        — Run 03_verify_topics.sh on Pi
#   ./ssh_into_pi.sh <PI_IP> workflow      — Run daily_workflow.sh on Pi
#
# Credentials: user = aadi_1234
# =============================================================================

PI_USER="aadi_1234"
PI_IP="${1:-}"
COMMAND="${2:-}"

if [ -z "$PI_IP" ]; then
    echo "[ERROR] Please provide the Raspberry Pi IP address."
    echo "        Usage: ./ssh_into_pi.sh <PI_IP> [command]"
    echo ""
    echo "  To find your Pi's IP on the local network:"
    echo "    Windows: arp -a | findstr raspberry"
    echo "    Ubuntu:  arp-scan --localnet | grep -i raspberry"
    exit 1
fi

echo "============================================="
echo "  SSH into Raspberry Pi"
echo "  User: $PI_USER"
echo "  IP  : $PI_IP"
echo "  Cmd : ${COMMAND:-interactive session}"
echo "============================================="
echo ""

# Remote script directory on the Pi
REMOTE_DIR="/home/$PI_USER/micro_ros_esp32/scripts"

case "$COMMAND" in
    "")
        echo "[INFO] Opening interactive SSH session..."
        ssh "$PI_USER@$PI_IP"
        ;;
    check)
        echo "[INFO] Running ESP32 check on Pi..."
        ssh "$PI_USER@$PI_IP" "bash $REMOTE_DIR/01_check_esp32.sh"
        ;;
    agent)
        echo "[INFO] Starting micro-ROS Agent on Pi..."
        ssh -t "$PI_USER@$PI_IP" "bash $REMOTE_DIR/02_start_agent.sh"
        ;;
    topics)
        echo "[INFO] Verifying topics on Pi..."
        ssh "$PI_USER@$PI_IP" "bash $REMOTE_DIR/03_verify_topics.sh"
        ;;
    nodes)
        echo "[INFO] Verifying nodes on Pi..."
        ssh "$PI_USER@$PI_IP" "bash $REMOTE_DIR/07_verify_nodes.sh"
        ;;
    validate)
        echo "[INFO] Running full validation on Pi..."
        ssh "$PI_USER@$PI_IP" "bash $REMOTE_DIR/08_validate_all.sh"
        ;;
    workflow)
        echo "[INFO] Running daily workflow on Pi..."
        ssh -t "$PI_USER@$PI_IP" "bash $REMOTE_DIR/daily_workflow.sh"
        ;;
    *)
        echo "[ERROR] Unknown command: '$COMMAND'"
        echo "        Valid: check | agent | topics | nodes | validate | workflow"
        exit 1
        ;;
esac
