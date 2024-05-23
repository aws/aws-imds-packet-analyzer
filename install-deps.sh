#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Please run as root (sudo)"
  exit 1
fi

# Check for supported operating systems
if grep -q "Amazon Linux 2023" /etc/os-release; then
    #amazon Linux 2023
    dnf install -y bcc-tools
elif grep -q "Amazon Linux 2" /etc/os-release  &&  grep -q 'VERSION="2"' /etc/os-release ; then
    #amazon linux 2
    if [ ! -z "${SUDO_USER}" ]; then
        echo  "[INFO] Running with sudo..checking if SUDO_USER: '${SUDO_USER}' has home dir to support amazon-linux-extras cache..."
        homedir=$( getent passwd "${SUDO_USER}" | cut -d: -f6 )
        if [ -d ${homedir} ]; then
            echo "[INFO] SUDO_USER: ${SUDO_USER} homedir '${homedir}' exists, moving forward with BCC installs"
        else
            echo  "[ERROR] SUDO_USER: ${SUDO_USER} homedir '${homedir}' does not exist, please create to support amazon-linux-extras cache"
            exit 1
        fi
    fi
    # enable BCC extra
    amazon-linux-extras enable BCC
    # dependencies
    yum -y install kernel-devel-$(uname -r) bcc-devel
elif grep -q 'ID=debian' /etc/os-release  &&  grep -q 'VERSION_ID="11"' /etc/os-release  ; then
    #debian 11
    #Avoid duplication of repo URL
    if ! grep -xq 'deb http://cloudfront.debian.net/debian sid main' /etc/apt/sources.list ; then
         echo deb http://cloudfront.debian.net/debian sid main | sudo tee -a /etc/apt/sources.list
    else
         echo "[INFO] Debian Repo URL exists in /etc/apt/sources.list."
    fi
    apt-get update
    #Set the environment variable DEBIAN_FRONTEND to 'noninteractive' to avoid the prompts and accept the default answers
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev linux-headers-$(uname -r) bcc --no-install-recommends
elif grep -q 'ID=debian' /etc/os-release  &&  grep -q 'VERSION_ID="10"' /etc/os-release  ; then
    #debian 10
    #Avoid duplication of repo URL
    if ! grep -xq 'deb http://cloudfront.debian.net/debian sid main' /etc/apt/sources.list ; then
       echo deb http://cloudfront.debian.net/debian sid main | sudo tee -a /etc/apt/sources.list
    else
       echo "[INFO] Debian Repo URL exists in /etc/apt/sources.list."
    fi
    apt-get update
    #Set the environment variable DEBIAN_FRONTEND to 'noninteractive' to avoid the prompts and accept the default answers
    export DEBIAN_FRONTEND=noninteractive
    # "|| true" helps bash to ignore error and return success, prevents the script to stop if execution fails
    apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev linux-headers-$(uname -r) bcc --no-install-recommends || true
    #Steps to fix the libcrypt1 error
    cd /tmp/
    apt -y download libcrypt1
    dpkg-deb -x libcrypt1* .
    cp -av lib/x86_64-linux-gnu/* /lib/x86_64-linux-gnu/
    #Re-run the install command
    apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev linux-headers-$(uname -r) bcc --no-install-recommends || true
    apt install -y --fix-broken || true
    # Run the install command
    apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev linux-headers-$(uname -r) bcc  --no-install-recommends
elif grep -q 'ID=ubuntu' /etc/os-release  &&  grep -q 'VERSION_ID="22.04"' /etc/os-release  ; then
    #Ubuntu 22.04
    apt-get update
    #Build bcc from the source
    apt install -y bison build-essential cmake flex git libedit-dev libllvm14 llvm-14-dev libclang-14-dev python3 zlib1g-dev libelf-dev libfl-dev python3-distutils zip  --no-install-recommends
    if [ -d "/home/ubuntu/" ] ; then
        echo "[INFO] Directory '/home/ubuntu/' exists, moving forward with BCC installs"
        cd /home/ubuntu/
        #Handle error : destination path 'bcc' already exists during git clone.
        if [ -d "/home/ubuntu/bcc" ]; then
            rm -rf /home/ubuntu/bcc
            git clone https://github.com/iovisor/bcc.git bcc
        else
            git clone https://github.com/iovisor/bcc.git bcc
        fi
        mkdir bcc/build; cd bcc/build
        cmake ..
        make
        make install
        cmake -DPYTHON_CMD=python3 .. # build python3 binding
        pushd src/python/
        make
        sudo make install
        popd
        apt-get -y install linux-headers-$(uname -r)
    else
        echo  "[ERROR] Directory '/home/ubuntu/' does not exist, please create to support BCC build"
        exit 1
    fi
elif grep -q 'ID=ubuntu' /etc/os-release  &&  grep -q 'VERSION_ID="20.04"' /etc/os-release  ; then
    #Ubuntu 20.04
    apt-get update
   #Build bcc from the source
    apt install -y bison build-essential cmake flex git libedit-dev libllvm12 llvm-12-dev libclang-12-dev python zlib1g-dev libelf-dev libfl-dev python3-distutils zip  --no-install-recommends
    if [ -d "/home/ubuntu/" ] ; then
        echo "[INFO] Directory '/home/ubuntu/' exists, moving forward with BCC installs"
        cd /home/ubuntu/
        #Handle error : destination path 'bcc' already exists during git clone.
        if [ -d "/home/ubuntu/bcc" ]; then
            rm -rf /home/ubuntu/bcc
            git clone https://github.com/iovisor/bcc.git bcc
        else
            git clone https://github.com/iovisor/bcc.git bcc
        fi
        mkdir bcc/build; cd bcc/build
        cmake ..
        make
        make install
        cmake -DPYTHON_CMD=python3 .. # build python3 binding
        pushd src/python/
        make
        sudo make install
        popd
        apt-get -y install linux-headers-$(uname -r)
    else
        echo  "[ERROR] Directory '/home/ubuntu/' does not exist, please create to support BCC build"
        exit 1
    fi
elif grep -q 'ID="rhel"' /etc/os-release; then
    #RHEL 8 and 9
    yum -y install bcc-tools libbpf
elif grep -q 'ID=fedora' /etc/os-release; then
    #Fedora
    yum -y install bcc-tools libbpf
elif grep -q 'ID="sles"' /etc/os-release  && grep -q 'VERSION_ID="15.[0-4]"' /etc/os-release ; then
    #SLES 15
    zypper ref
    zypper in -y  bcc-tools bcc-examples
    zypper in -y --oldpackage kernel-default-devel-$(zypper se -s kernel-default-devel | awk '{split($0,a,"|"); print a[4]}' | grep $(uname -r | awk '{gsub("-default", "");print}') | sed -e 's/^[ \t]*//' | tail -n 1)
elif grep -q "CentOS Stream" /etc/os-release; then
    #CentOS
    yum -y install bcc
else
    echo "[ERROR] Unsupported operating system"
    exit 1
fi
