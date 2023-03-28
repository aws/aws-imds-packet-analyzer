#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

#check if shell script is running as root => su permissions to edit /etc/systemd/system dir
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Please run as root (sudo)"
  exit 1
fi

bpf_trace_service="imds_tracer_tool.service"
bpf_trace_path=$(pwd)
bpf_trace_systemd_path="/etc/systemd/system/$bpf_trace_service"

echo "--- removing old service file"
rm $bpf_trace_systemd_path

echo "--- create new Unit file"
touch $bpf_trace_systemd_path

echo "--- add service details"
echo "[Unit]" >> $bpf_trace_systemd_path
echo "Description=ImdsPacketAnalyzer IMDS detection tooling from AWS" >> $bpf_trace_systemd_path
echo "Before=network-online.target" >> $bpf_trace_systemd_path
echo "After=multi-user.target" >> $bpf_trace_systemd_path
echo "" >> $bpf_trace_systemd_path

echo "[Service]" >> $bpf_trace_systemd_path
echo "Type=simple" >> $bpf_trace_systemd_path
echo "Restart=always" >> $bpf_trace_systemd_path
echo "WorkingDirectory=$bpf_trace_path" >> $bpf_trace_systemd_path
echo "ExecStart=/bin/python3 $bpf_trace_path/src/imds_snoop.py" >> $bpf_trace_systemd_path

echo "" >> $bpf_trace_systemd_path
echo "[Install]" >> $bpf_trace_systemd_path
echo "WantedBy=multi-user.target" >> $bpf_trace_systemd_path

echo "--- Service details:"
echo ""
cat $bpf_trace_systemd_path

echo ""
echo "--- reload daemon and enable the $bpf_trace_service service"
systemctl daemon-reload
systemctl enable $bpf_trace_service

echo "--- start the $bpf_trace_service service"
# For normal service we would start in activate, but we're starting here as we want to detect all IMDSv1 calls as early as possible
systemctl start $bpf_trace_service

echo "--- done"