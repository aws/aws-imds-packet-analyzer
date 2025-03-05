#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e  # Exit on error

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Please run as root (sudo)" >&2
    exit 1
fi

# Function to install BCC on Ubuntu
install_ubuntu_bcc() {
    local llvm_version=$1
    apt-get update
    apt install -y bison build-essential cmake flex git libedit-dev "libllvm${llvm_version}" \
        "llvm-${llvm_version}-dev" "libclang-${llvm_version}-dev" python3 zlib1g-dev libelf-dev \
        libfl-dev python3-distutils zip --no-install-recommends

    if [ ! -d "/home/ubuntu" ]; then
        echo "[ERROR] Directory '/home/ubuntu' does not exist" >&2
        exit 1
    fi

    cd /home/ubuntu
    rm -rf bcc
    git clone https://github.com/iovisor/bcc.git
    cd bcc
    mkdir -p build && cd build
    cmake ..
    make && make install
    cmake -DPYTHON_CMD=python3 ..
    cd src/python
    make && make install
    apt-get -y install "linux-headers-$(uname -r)"
}

# Function to check sudo user home directory
check_sudo_user_home() {
    if [ -n "${SUDO_USER}" ]; then
        local homedir=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
        if [ ! -d "${homedir}" ]; then
            echo "[ERROR] SUDO_USER: ${SUDO_USER} homedir '${homedir}' does not exist" >&2
            exit 1
        fi
    fi
}

# Function to add Debian repository
add_debian_repo() {
    local repo_line="deb http://cloudfront.debian.net/debian sid main"
    if ! grep -qx "$repo_line" /etc/apt/sources.list; then
        echo "$repo_line" | tee -a /etc/apt/sources.list
    fi
}

# Install BCC based on OS
case "$(. /etc/os-release; echo "$ID$VERSION_ID")" in
    "amzn2023")
        dnf install -y bcc-tools
        ;;
    "amzn2")
        check_sudo_user_home
        amazon-linux-extras enable BCC
        yum -y install "kernel-devel-$(uname -r)" bcc-devel
        ;;
    "debian11")
        add_debian_repo
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev "linux-headers-$(uname -r)" bcc --no-install-recommends
        ;;
    "debian10")
        add_debian_repo
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev "linux-headers-$(uname -r)" bcc --no-install-recommends || true
        cd /tmp
        apt -y download libcrypt1
        dpkg-deb -x libcrypt1* .
        cp -av lib/x86_64-linux-gnu/* /lib/x86_64-linux-gnu/
        apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev "linux-headers-$(uname -r)" bcc --no-install-recommends
        apt install -y --fix-broken
        ;;
    "ubuntu22.04")
        install_ubuntu_bcc 14
        ;;
    "ubuntu20.04")
        install_ubuntu_bcc 12
        ;;
    "rhel"*)
        yum -y install bcc-tools libbpf
        ;;
    "fedora"*)
        yum -y install bcc-tools libbpf
        ;;
    "sles15"*)
        zypper ref
        zypper in -y bcc-tools bcc-examples
        zypper in -y --oldpackage "kernel-default-devel-$(zypper se -s kernel-default-devel | awk '{split($0,a,"|"); print a[4]}' | grep "$(uname -r | sed 's/-default//')" | sed -e 's/^[ \t]*//' | tail -n 1)"
        ;;
    "centos"*)
        yum -y install bcc
        ;;
    *)
        echo "[ERROR] Unsupported operating system" >&2
        exit 1
        ;;
esac

echo "[INFO] BCC installation completed successfully"