#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

BPF_TRACE_SERVICE="imds_tracer_tool.service"
BPF_TRACE_SYSTEMD_PATH="/etc/systemd/system/$BPF_TRACE_SERVICE"
LOG_DIR="/var/log/imds"

# Check if script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Please run as root (sudo)" >&2
    exit 1
fi

# Function to stop and remove the service
remove_service() {
    echo "--- Stopping tracer service"
    systemctl stop "$BPF_TRACE_SERVICE" || echo "[WARNING] Failed to stop service. It may not be running."

    echo "--- Removing service file (unit file)"
    rm -f "$BPF_TRACE_SYSTEMD_PATH"

    echo "--- Reloading daemons"
    systemctl daemon-reload
}

# Function to display log information
display_log_info() {
    echo
    echo "[INFO] Associated log files can be found in the $LOG_DIR directory"
    echo "To delete all log files, run the following command:"
    echo "sudo rm $LOG_DIR/imds-trace.*"
}

# Main script execution
remove_service
display_log_info

echo
echo "--- Uninstallation complete"