#!/bin/bash
# =============================================================================
# deploy_to_pi.sh
# Copy all scripts from this folder to the Raspberry Pi over SSH.
#
# Usage: ./deploy_to_pi.sh <PI_IP>
#   Run this ONCE from your laptop (Windows Git Bash / Ubuntu terminal).
# =============================================================================

PI_USER="aadi_1234"
PI_IP="${1:-}"
REMOTE_DIR="/home/$PI_USER/micro_ros_esp32/scripts"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$PI_IP" ]; then
    echo "[ERROR] Provide the Pi IP address."
    echo "        Usage: ./deploy_to_pi.sh <PI_IP>"
    exit 1
fi

echo "============================================="
echo "  Deploying Scripts to Raspberry Pi"
echo "  From: $LOCAL_DIR"
echo "  To  : $PI_USER@$PI_IP:$REMOTE_DIR"
echo "============================================="
echo ""

# Create remote directory
echo "[1/3] Creating remote directory..."
ssh "$PI_USER@$PI_IP" "mkdir -p $REMOTE_DIR"
echo "[OK]"

# Copy all .sh files
echo "[2/3] Copying scripts..."
scp "$LOCAL_DIR"/*.sh "$PI_USER@$PI_IP:$REMOTE_DIR/"
echo "[OK]"

# Make all scripts executable on the Pi
echo "[3/3] Setting execute permissions..."
ssh "$PI_USER@$PI_IP" "chmod +x $REMOTE_DIR/*.sh"
echo "[OK]"

echo ""
echo "============================================="
echo "  [SUCCESS] Scripts deployed!"
echo ""
echo "  SSH into the Pi and run:"
echo "    cd $REMOTE_DIR"
echo "    ./daily_workflow.sh"
echo "    ./08_validate_all.sh"
echo "============================================="
