# Introduction

The AWS ImdsPacketAnalyzer is a tool that traces TCP interactions with the EC2 Instance Metadata Service (IMDS). This can assist in identifying the processes making IMDSv1 calls on a host. Traces contain the `pid`, the `argv` used to launch the process, and the parent `pids` up to four levels deep. This information allows you to identify a Process making IMDSv1 calls for further investigation.

The ImdsPacketAnalyzer leverages the [BCC (BPF Compiler Collection)](https://github.com/iovisor/bcc/blob/master/INSTALL.md#Amazon-Linux-2---Binary). In order to successfully run the analyzer the BCC pre-requisites need to be installed.


# AWS ImdsPacketAnalyzer

- [Packages - Installing BCC](#packages---installing-bcc)
    - [Amazon Linux 2023](#amazon-linux-2023)
	- [Amazon Linux 2](#amazon-linux-2)
	- [Amazon Linux 1, 2018.03](#amazon-linux-1-201803)
	- [Debian 11](#debian-11)
	- [Debian 10](#debian-10)
	- [Ubuntu 20 / 22](#ubuntu-20--22)
	- [RHEL 8 / 9](#rhel-8--9)
	- [SLES 15](#sles-15)
	- [Windows](#windows)
- [Usage](#usage-)
    - [Amazon Linux 2023](#amazon-linux-2023-1)
	- [Amazon Linux 2](#amazon-linux-2-1)
	- [Amazon Linux 1](#amazon-linux-1)
	- [Debian 11](#debian-11-1)
	- [Debian 10](#debian-10-1)
	- [Ubuntu 20 / 22](#ubuntu-20--22-1)
	- [RHEL 8 / 9](#rhel-8--9-1)
	- [SLES 15](#sles-15-1)
	- [Windows](#windows-1)
- [Logging](#logging)
- [Running the tool as a service](#running-the-tool-as-a-service)
	- [Activating the tool as a service](#activating-the-tool-as-a-service)
	- [Deactivating the tool as a service](#deactivating-the-tool-as-a-service)
- [Limitations](#limitations)


# Packages - Installing BCC
For hosts with internet access, the install script can be used. It is advised that this script is run only on non-production instances. Installation will update dependancies and may affect other functionality.
For instances without internet access you will need to share the files on an S3 folder.
```
sudo bash install-deps.sh
```
---

**OR** run  the following commands per OS


## Amazon Linux 2023

Install BCC

```
sudo dnf install bcc-tools
```
---

## Amazon Linux 2

Install [BCC (BPF Compiler Collection)](https://github.com/iovisor/bcc/blob/master/INSTALL.md#Amazon-Linux-2---Binary):

```
sudo amazon-linux-extras enable BCC
sudo yum install kernel-devel-$(uname -r)
sudo yum install bcc
```
---

## Amazon Linux 1, 2018.03
 
Install [BCC (BPF Compiler Collection)](https://github.com/iovisor/bcc/blob/master/INSTALL.md#Amazon-Linux-1---Binary):
 
```
sudo yum install kernel-headers-$(uname -r | cut -d'.' -f1-5)
sudo yum install kernel-devel-$(uname -r | cut -d'.' -f1-5)
sudo yum install bcc
```
---

## Debian 11

```
echo deb http://cloudfront.debian.net/debian sid main | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev linux-headers-$(uname -r)
sudo apt-get install linux-headers-$(uname -r) bcc
```
---

## Debian 10

Note : During the Dependency installation, the ["libcrypt1"](https://www.mail-archive.com/debian-bugs-dist@lists.debian.org/msg1818037.html) related error occurs so the execution has step to fix and continue with the installation process further, also the OS libraries can cause the restart of the system releated services like sshd and crond.

```
echo deb http://cloudfront.debian.net/debian sid main | sudo tee -a /etc/apt/sources.list
sudo -i         # Need to switch to root user in the CLI before running below command
apt-get update
#Set the environment variable DEBIAN_FRONTEND to 'noninteractive' to avoid the prompts and accept the default answers
export DEBIAN_FRONTEND=noninteractive
apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev linux-headers-$(uname -r) bcc --no-install-recommends
#Steps to fix the libcrypt1 error
cd /tmp/
apt -y download libcrypt1
dpkg-deb -x libcrypt1* .
cp -av lib/x86_64-linux-gnu/* /lib/x86_64-linux-gnu/
#Re-run the install command
apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev linux-headers-$(uname -r) bcc --no-install-recommends
apt install -y --fix-broken
# Run the install command
apt-get install -y bpfcc-tools libbpfcc libbpfcc-dev linux-headers-$(uname -r) bcc --no-install-recommends
```
---

## Ubuntu 20 / 22
```
sudo apt install -y bison build-essential cmake flex git libedit-dev libllvm14 llvm-14-dev libclang-14-dev python3 zlib1g-dev libelf-dev libfl-dev python3-distutils
git clone https://github.com/iovisor/bcc.git
mkdir bcc/build; cd bcc/build
cmake ..
make
sudo make install
cmake -DPYTHON_CMD=python3 .. # build python3 binding
pushd src/python/
make
sudo make install
popd
sudo apt-get install linux-headers-$(uname -r)
```
---

## RHEL 8 / 9

```
sudo yum -y install bcc-tools libbpf
```
---

## SLES 15
```
sudo zypper ref
sudo zypper in bcc-tools bcc-examples
sudo zypper in --oldpackage kernel-default-devel-$(zypper se -s kernel-default-devel | awk '{split($0,a,"|"); print a[4]}' | grep $(uname -r | awk '{gsub("-default", "");print}') | sed -e 's/^[ \t]*//' | tail -n 1)
```

---

## WINDOWS

INSTALL PYTHON
- Check if Python is installed with ```python -V```
- Download python3 msi https://www.python.org/downloads/
- Select to add python.exe to PATH


INSTALL PIP
- Check if PIP is installed with ```pip help```
- Download PIP ```curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py```
- Install with ```python get-pip.py```


INSTALL GIT
- Check if GIT is installed with ```git version```
- Download ad install the MSI for Windows via ```https://git-scm.com/download/win```


INSTALL AWS CLI
- Run ```msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi```
- Run and configure the CLI with ```aws configure```
- Ensure EC2 Instance IAM Profile is assigned with access to Cloudwatch.


INSTALL METABADGER (https://github.com/salesforce/metabadger)
- Run ```pip3 install --user metabadger```
- Go to working directory ```cd C:\<Users>\<Administrator>\AppData\Roaming\Python\Python311\scripts```

---

**Note:** Troubleshooting + Installation on other distros please see: [BCC (BPF Compiler Collection)](https://github.com/iovisor/bcc/blob/master/INSTALL.md)

---

## Usage 
BCC requires that the analyzer is run with root permissions. Typically, you can execute the following script and IMDS calls will be logged to the console and to a log file by default (see [logging.conf](#log-configuration)).
```
sudo python3 src/imds_snoop.py
```


#### Example v1 call:
The following IMDSv1 curl command
```
curl http://169.254.169.254/latest/meta-data/
```
will result the following IMDS packet analyzer output
```
IMDSv1(!) (pid:6028:curl argv:curl http://169.254.169.254/latest/meta-data/) called by -> (pid:6027:makeCalls.sh argv:/bin/bash ./makeCalls.sh) -> (pid:4081:zsh argv:-zsh) -> (pid:4081:sshd argv:sshd: kianred@pts/0)
```
---

## Amazon Linux 2023
```
sudo python3 src/imds_snoop.py
```
---

## Amazon Linux 2
```
sudo python3 src/imds_snoop.py
```
---

## Amazon Linux 1
```
sudo python3 src/imds_snoop.py
```
---

## Debian 11
```
sudo python3 src/imds_snoop.py
```
---

## Debian 10
```
sudo python3 src/imds_snoop.py
```
---

## Ubuntu 20 / 22
```
sudo LD_PRELOAD=/home/ubuntu/bcc/build/src/cc/libbcc.so.0 PYTHONPATH=/home/ubuntu/bcc/build/src/python src/imds_snoop.py
```
---

## RHEL 8 / 9
```
sudo python3 src/imds_snoop.py
```
---

## SLES 15
```
sudo python3 src/imds_snoop.py
```
---

## WINDOWS
- From the Working directory E.g ```cd C:\<Users>\<Administrator>\AppData\Roaming\Python\Python311\scripts```
- Run to view IMDSv1 calls: ```metabadger cloudwatch-metrics --region us-east-1```

The output table will highlight if the instance has made IMDSv1 calls

To find the specific app making the IMDSv1 calls, use the inbuilt Windows Resource Monitor Network monitor to find the Image and PID of the application making calls.

To do this, open Resource Monitor (Start->Search ->Resource Monitor) and click on the Network tab.
Then look for calls in the Network Activity section made to either the IP or DNS entries listed:
- IP: ```169.254.169.254```
- DNS: instance-data.<region>.compute.internal E.g ```instance-data.us-east-1.compute.internal```

Network Analyzer will show the calls and you should proceed to update the software/application.

More details and thanks to https://github.com/salesforce/metabadger and https://www.greystone.co.uk/2022/03/24/how-greystone-upgraded-its-aws-ec2-instances-to-use-instance-meta-data-service-version-2-imdsv2/


---

# Logging
The ImdsPacketAnalyzer will also capture IMDS calls to log files. Log entries follow the format: `[Time] [Level] [message]` where:
- **Time:** the time at which the IMDS call was made in the format: `%Y-%m-%dT%H:%M:%S` eg.) [2022-12-20T12:57:51]
- **Level:** the level of the log entry, where IMDSv2 calls are logged at `INFO` level and IMDSv1 calls are logged at `WARNING` level
    - If there are any instances where an ImdsPacketAnalyser fail to interpret the packets, `ERROR` level messages will be traced.
    - **Note** The only reason a call cannot be identified is if the analyzer is unable to find a request payload for the IMDS call, this missing payload means the analyzer will not be able to discern V1 from V2 IMDS calls. (see what to do in case of missing payload below).
    - Errors (due to a *missing payload*) in the log indicate that the analyzer was not able to capture the payload that was sent to the IMDS ip.  This is expected for AL2 kernel 4.14 on Granite (ARM) instances (see "Limitations" heading below).   If this is a new error case, please log a defect with detailed information and consider alternative ways to identify the source of the IMDS call.
- **message:** the details of the IMDS call as it would be outputted to the terminal

Example of a IMDSv1 log entry:
```
[2022-12-20T11:03:58] [WARNING] IMDSv1(!) (pid:1016:curl argv:curl http://169.254.169.254/latest/meta-data/) called by -> (pid:1015:makeCalls.sh argv:/bin/bash ./makeCalls.sh) -> (pid:32678:zsh argv:-zsh) -> (pid:32678:sshd argv:sshd: )
```
Example of a IMDSv2 log entry:
```
[2022-12-20T11:03:58] [INFO] IMDSv2 (pid:1018:curl argv:curl -H X-aws-ec2-metadata-token: AQAEAFEOMInKb-S7me-hLqzu83lYdeDV7r-sPh2D4SJF6v5IwD4S8g== -v http://169.254.169.254/latest/meta-data/) called by -> (pid:1015:makeCalls.sh argv:/bin/bash ./makeCalls.sh) -> (pid:32678:zsh argv:-zsh) -> (pid:32678:sshd argv:sshd: )
```

### Log configuration

The logging configuration can be adjusted by editing the **logging.conf** file.

By default:
- Logs will be saved to the `/var/log/` folder in a file called `imds-trace.log`
- Log files will be appended (if the analyzer is stopped and then run again on multiple occasions)
- Each log file will reach a maximum size of 1 megabyte before rollover occurs
- When a log file reaches 1mb in size it will rollover to a new log file **i.e) imds-trace.log.1 or imds-trace.log.2** 
- Rollover occurs a maximum of 5 times meaning that at most log files will at most take up 6 x 1mb => 6mb storage space (the prominent `imds-trace.log` file + 5 rollover log files `imds-trace.log.x` where x ranges from 1 to **backupCount**)

### Analyzing log files
**Assuming default logging setup:** 
- Running the command `cat /var/log/imds-trace.* | grep WARNING` will output all IMDSv1 calls to the terminal. 
- Note that this grep will only identify the call, sometimes the calls leading up to the V1 call can provide additional context.   

# Running the tool as a service

## Activating the tool as a service
Configuring the analyzer to run as a service will ensure that the tool will run as soon as possible upon the boot up of an instance. This will increase the chances of identifying services making IMDSv1 calls as early as the instance is inited onto a network. 

A shell script has been provided in the package that will automate the process of setting up the analyzer tool as a service. **Note:** the script/service will only work if the structure of the package is left unchanged. 

Run the script from the command line as follows:

```
sudo ./activate-tracer-service.sh
```

or

```
sudo bash activate-tracer-service.sh
```

The permissions for the shell script may need to be changed using:
```
chmod +x activate-tracer-service.sh
```

You can check if the service is running after activating the service or a host reboot:
```
systemctl status -l imds_tracer_tool.service
```

## Deactivating the tool as a service
When the tool is configured as a service using the previous script, a service file is added into the OS. In order to restore the system, run the script from the command line:

```
sudo ./deactivate-tracer-service.sh
```

or

```
sudo bash deactivate-tracer-service.sh
```

Permissions for the script may need to be changed:
```
chmod +x deactivate-tracer-service.sh
```

---

## Limitations
We are aware of some limitations with the current version of the ImdsPacketAnalyzer.  Contributions are welcomed.
- The `install-deps.sh` script assumes AL2 and internet connectivity
- Althought the ImdsPacketAnalyser have been run on multiple distributions, it is only tested on AL2 before new commits are pushed.
- ImdsPacketAnalyzer only supports IPv4
- ImdsPacketAnalyzer is intended to be used to identify processes making IMDSv1 calls. There is no guarnatee that it will catch all IMDS calls and it is possible that a network can be configured to route other traffic to the IMDS ip address. The analyzer is reliable enough to be used as a tool to detect IMDSv1 calls.
- ImdsPacketAnalyser has not been tested with production traffic in mind, it is intended to be run as a analysis tool to be removed once the source of IMDSv1 calls have been identified.
- AL2 kernel 4.14 on Graviton (ARM) lack the eBPF features required to determine if a call is IMDSv1 or V2.  This is reported as `{MISSING PAYLOAD}` error.  We do not have a workaround for this and do not have a planned fix.