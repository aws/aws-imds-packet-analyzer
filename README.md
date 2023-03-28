# AWS ImdsPacketAnalyzer

The AWS ImdsPacketAnalyzer is a tool that traces TCP interactions with the EC2 Instance Metadata Service (IMDS). This can assist in identifying the processes making IMDSv1 calls on a host. Traces contain the `pid`, the `argv` used to launch the process, and the parent `pids` up to four levels deep. This information allow you to identify a Process making IMDSv1 calls for further investigation. 


## Installation
The ImdsPacketAnalyzer leverages the [BCC (BPF Compiler Collection)](https://github.com/iovisor/bcc). In order to successfully run the analyzer the BCC pre-requisites need to be installed.  

### Amazon Linux 2 (AL2)
For AL2 hosts with internet access, either a installation script,
```
sudo ./install-deps.sh
```
or, the steps detailed in the [BCC documentation](https://github.com/iovisor/bcc/blob/master/INSTALL.md#Amazon-Linux-2---Binary)

```
sudo amazon-linux-extras enable BCC
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

sudo yum install kernel-devel-$(uname -r)
sudo yum install bcc
```
can be used.  For instances without internet access you will need to share the files on an S3 folder.

### Amazon Linux 1, 2018.03

Install [BCC (BPF Compiler Collection)](https://github.com/iovisor/bcc/blob/master/INSTALL.md#Amazon-Linux-1---Binary):

```
sudo yum install kernel-headers-$(uname -r | cut -d'.' -f1-5)
sudo yum install kernel-devel-$(uname -r | cut -d'.' -f1-5)
sudo yum install bcc
```

**Note:** Troubleshooting + Installation on other distros please see: [BCC (BPF Compiler Collection)](https://github.com/iovisor/bcc/blob/master/INSTALL.md)


## Usage 
BCC require that the analyze is run with root permissions. Typically you can execute the following script `sudo python3 src/imds_snoop.py`. IMDS calls will be logged to the console and to a log file by default (see [logging.conf](logging.conf)). 

#### Example v1 call:
The following IMDSv1 curl command
```
curl http://169.254.169.254/latest/meta-data/
```
will result the following analyzer output
```
IMDSv1(!) (pid:6028:curl argv:curl http://169.254.169.254/latest/meta-data/) called by -> (pid:6027:makeCalls.sh argv:/bin/bash ./makeCalls.sh) -> (pid:4081:zsh argv:-zsh) -> (pid:4081:sshd argv:sshd: kianred@pts/0)
```

## Logging
The ImdsPacketAnalyzer will also capture IMDS calls to log files. Log entries follow the format: `[Time] [Level] [message]` where:
- **Time:** the time at which the IMDS call was made in the format: `%Y-%m-%dT%H:%M:%S` eg.) [2022-12-20T12:57:51]
- **Level:** the level of the log entry, where IMDSv2 calls are logged at `INFO` level and IMDSv1 calls are logged at `WARNING` level
    - If there are any instances where an ImdsPacketAnalyser fail to interpret the packets, `ERROR` level messages will be traced.
    - **Note** The only reason a call cannot be identified is if the analyzer is unable to find a request payload for the IMDS call, this missing payload means the analyzer will not be able to discern V1 from V2 IMDS calls. (see what to do in case of missing payload below).
    - Errors (due to a *missing payload*) in the log indicate that the analyzer was not able to capture the payload that was sent to the IMDS ip.  Please log a defect with detailed information and consider alternative ways to identify the source of the IMDS call.
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
- Logs will be saved to the `/var/logs/` folder in a file called `imds-trace.log`
- Log files will be appended (if the analyzer is stopped and then run again on multiple occasions)
- Each log file will reach a maximum size of 1 megabyte before rollover occurs
- When a log file reaches 1mb in size it will rollover to a new log file **i.e) imds-trace.log.1 or imds-trace.log.2** 
- Rollover occurs a maximum of 5 times meaning that at most log files will at most take up 6 x 1mb => 6mb storage space (the prominent `imds-trace.log` file + 5 rollover log files `imds-trace.log.x` where x ranges from 1 to **backupCount**)

### Analyzing log files
**Assuming default logging setup:** 
- Running the command `cat /var/log/imds-trace.* | grep WARNING` will output all IMDSv1 calls to the terminal. 
- Note that this grep will only identify the call, sometimes the calls leading up to the V1 call can provide additional context.  

## Running the tool as a service

### Activating the tool as a service
Configuring the analyzer to run as a service will ensure that the tool will run as soon as possible even upon the boot up of an instance. This will increase the chances of identifying services making IMDSv1 calls even as early as the instance is inited onto a network. 

A shell script has been provided in the package that will automate the process of setting up the analyzer tool as a service. **Note:** the script/service will only work if the structure of the package is left unchanged. 

Run the script from the command line as follows:
```
sudo ./activate-tracer-service.sh
```

you might need to change the file permissions with:
```
chmod 777 activate-tracer-service.sh
```

### Deactivating the tool as a service
When the tool is configured as a service using the previous script a service file is added into the OS. In order to restore the system run the script from the command line:
```
sudo ./deactivate-tracer-service.sh
```
Permissions for the script may need to be changed:
```
chmod 777 deactivate-tracer-service.sh
```