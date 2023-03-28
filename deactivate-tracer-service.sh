#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

#check if shell script is running as root => su permissions to edit /etc/systemd/system dir
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Please run as root (sudo)"
  exit 1
fi

bpf_trace_service="imds_tracer_tool.service"
bpf_trace_systemd_path="/etc/systemd/system/$bpf_trace_service"

echo "--- stopping tracer service"
systemctl stop imds_tracer_tool.service

echo "--- removing service file (unit file)"
rm $bpf_trace_systemd_path

echo "--- reload daemons"
systemctl daemon-reload

echo ""

echo "[INFO] Associated log files can be found in the /var/log/ directory"
echo "Run the following command to delete all log files: "
echo "sudo rm /var/log/imds-trace.*"