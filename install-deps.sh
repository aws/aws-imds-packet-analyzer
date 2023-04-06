#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Please run as root (sudo)"
  exit 1
fi

if ! grep -q "Amazon Linux 2" /etc/os-release; then
  echo "[ERROR] Only Amazon Linux 2 supported at this time."
  echo "[ERROR] For other linux flavours you will need to manually install bcc and python-bcc"  exit 1
fi

# amazon-linux-extras cache uses sudo_user's homedir if called with sudo or /var/cache if directly run as root
#  the extras command will fail if user homdir doesn't exist
if [ ! -z "${SUDO_USER}" ]; then
  echo "[INFO] Running with sudo..checking if SUDO_USER: '${SUDO_USER}' has home dir to support amazon-linux-extras cache..."
  homedir=$( getent passwd "${SUDO_USER}" | cut -d: -f6 )
  if [ -d ${homedir} ]; then
    echo "[INFO] SUDO_USER: ${SUDO_USER} homedir '${homedir}' exists, moving forward with BCC installs"
  else
    echo "[ERROR] SUDO_USER: ${SUDO_USER} homedir '${homedir}' does not exist, please create to support amazon-linux-extras cache"
    exit 1
  fi
fi

# enable bcc extra
amazon-linux-extras enable BCC

# dependencies
yum -y install kernel-devel-$(uname -r) bcc-devel