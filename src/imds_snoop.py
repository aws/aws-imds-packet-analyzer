#!/usr/bin/python3
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

from bcc import BPF
import os
import logging
from logging.handlers import RotatingFileHandler
from logging.config import fileConfig

EC_METADATA_TOKEN_ = "x-aws-ec2-metadata-token:"

LOGGING_CONFIG_FILE = 'logging.conf'
LOG_IMDS_FOLDER = "/var/log/imds"

# GLOBAL => set logger object as global because initializing the logger in the bpf callback function could
# cause unnecessary overhead
logger = None

"""Check if a IMDS call is a imdsV1/2 call

:param payload: payload of network call
:type payload: str
:returns: is_v2
:rtype is_v2: bool
"""
def check_v2(payload: str, is_debug=False) -> bool:
    if (is_debug):
        print("========================================================================")
        print("[DEBUG] Payload being checked: ")
        print(payload, end="\n")
        print("========================================================================")

    IMDSV2_TOKEN_PREFIX = "x-aws-ec2-metadata-token"

    # determine if event was imdsv2 call or not
    is_v2 = False
    if IMDSV2_TOKEN_PREFIX in payload.lower():
        is_v2 = True

    return (is_v2)


"""Remove the token from the message 

:param comms: message that need to be redacted.
:type: str
:returns: redacted message
:rtype: str
"""
def hideToken(comms: str) -> str:
    startToken = comms.find(EC_METADATA_TOKEN_)
    endToken = comms.find("==", startToken) + len("==")

    if (startToken >= len(EC_METADATA_TOKEN_)) and (endToken > startToken):
        newTxt = comms[:startToken] + "**token redacted**" + comms[endToken:]
    else:
        newTxt = comms

    return newTxt

def recurseHideToken(comms: str) -> str:
    newTxt = comms.lower()
    while newTxt.find(EC_METADATA_TOKEN_) >= 0:
        newTxt = hideToken(newTxt)

    return newTxt

""" get argv info per calling process

:param pid: process id of calling process
:type pid: int
:param proc_name: name of calling process
:type proc_name: str
:returns: proc_info
:rtype proc_info: str
"""
def get_proc_info(pid: int, proc_name: str, is_debug=False) -> str:
    if (is_debug):
        print("========================================================================")
        print("[DEBUG] pid: " + str(pid))
        print("proc_name: " + proc_info, end="\n")
        print("========================================================================")

    try:
        cmdline = open("/proc/" + str(pid) + "/cmdline").read()
        proc_info = ":" + proc_name
        proc_info += " argv:" + cmdline.replace('\x00', ' ').rstrip()
        return (proc_info)
    except Exception as e:
        print("Info: ", e)
        error_message = " Unable to get argv information"
        return (error_message)


""" generate output message per imds network call

:param is_v2: flag to represent whether or not the current event is an imdsv1 or imdsv2 event
:type is_v2: bool
:param event: event object returned by C code into per_buffers -> essentially the imds_http_data_t struct in the C code
:type event: bcc.table
:returns: log_msg
:rtype log_msg: str
"""
def gen_log_msg(is_v2: bool, event) -> str:
          
    entry_init = "(pid:"
    log_msg = "IMDSv2 " if is_v2 else "IMDSv1(!) "

    log_msg += entry_init + \
        str(event.pid[0]) + get_proc_info(event.pid[0],
                                          event.comm.decode()) + ")"

    if event.parent_comm and event.pid[1]:
        log_msg += " called by -> " + entry_init + \
            str(event.pid[1]) + get_proc_info(event.pid[1],
                                              event.parent_comm.decode()) + ")"
        if event.gparent_comm and event.pid[2]:
            log_msg += " -> " + entry_init + \
                str(event.pid[2]) + get_proc_info(event.pid[2],
                                                  event.gparent_comm.decode()) + ")"
            if event.ggparent_comm and event.pid[3]:
                log_msg += " -> " + entry_init + \
                    str(event.pid[3]) + get_proc_info(event.pid[3],
                                                      event.ggparent_comm.decode()) + ")"

    return log_msg


def print_imds_event(cpu, data, size):
    # let bcc generate the data structure from C declaration automatically given the eBPF event reference (int) -> essentially
    # generates the imds_http_data_t struct in the C code as a bcc.table object
    event = b["imds_events"].event(data)
    """event object
  :attribute pid: stores pids of calling processes in the communication chain (4 pids)
  :type pid: int array[4] (u32 ints)
  :attribute comm: communication process name
  :type comm: bytes (specific encoding unknown)
  :attribute parent_comm: communication process name (parent)
  :type parent_comm: bytes (specific encoding unknown)
  :attribute gparent_comm: communication process name (grand-parent)
  :type gparent_comm: bytes (specific encoding unknown)
  :attribute ggparent_comm: communication process name (great-grand-parent)
  :type parent_comm: bytes (specific encoding unknown)
  :attribute pkt_size: size packet request
  :type pkt_size: int (u32)
  :attribute pkt: the data payload contained in a network request of request
  :type pkt: bytes (specific encoding unknown)
  :attribute contains_payload: flag to indicate if the event has a viable payload to analyze or not
  :type contains_payload: int (u32) 
  """
    # pass whatever data bcc has captured as the event payload to test IMDSv1/2?
    is_v2 = check_v2(event.pkt[:event.pkt_size].decode())
    # generate information string to be logged
    log_msg = gen_log_msg(is_v2, event)
    pkt_size = event.pkt_size
    payload = event.pkt[:pkt_size].decode()
    log_msg = log_msg + " Req details: " + ", ".join(payload.splitlines())
    log_msg = recurseHideToken(log_msg)

    if(event.contains_payload):
      # log identifiable trace info
      if(is_v2):
        logger.info(log_msg)
        print('[INFO] ' + log_msg, end="\n")
      else:
        logger.warning(log_msg)
        print('[WARNING] ' + log_msg, end="\n")
    else:
      # unidentifiable call -> needs further attention -> hence log at error level
      log_msg = "{MISSING PAYLOAD} " + log_msg
      logger.error(log_msg)
      print('[ERROR] ' + log_msg, end="\n")


if(__name__ == "__main__"):
  if os.geteuid() != 0:
    exit("You need to have root privileges to run this script.")

  # create and lock down the logging folder, since root is running the trace, only root can view the log
  if not os.path.exists(LOG_IMDS_FOLDER):
    os.makedirs(LOG_IMDS_FOLDER)

  st = os.stat(LOG_IMDS_FOLDER)
  if bool(st.st_mode & 0o00077):
    print("Setting log folder to root RW access only, permission was: " + str(oct(st.st_mode & 0o00777)))
    os.chmod(LOG_IMDS_FOLDER, 0o600)  # only user RW needed.

  # initialize logger
  if os.path.exists(LOGGING_CONFIG_FILE):
    print("Using config file as one was provided.")
    fileConfig(LOGGING_CONFIG_FILE)
    logger = logging.getLogger()
  else:  # No config file is preferred as we want to ensure the locked down folder is used.
    print("Logging to /var/log/imds/imds-trace.log")
    logger = logging.getLogger()
    c_handler = RotatingFileHandler('/var/log/imds/imds-trace.log', 'a', 1048576, 5, 'UTF-8')
    logger.setLevel(logging.INFO)
    c_format = logging.Formatter('[%(asctime)s] [%(levelname)s] %(message)s')
    c_handler.setFormatter(c_format)
    logger.addHandler(c_handler)

  # initialize BPF
  b = BPF('bpf.c')
  # Instruments the kernel function event() using kernel dynamic tracing of the function entry, and attaches our C
  # defined function name() to be called when the kernel function is called.
  #
  # kernel update https://github.com/torvalds/linux/commit/81d03e2518945c4bc7b9a7b3f1935203954bf3ba cause the event to not fire, trying previous implementation now in `__sock_sendmsg`
  event_list = ['__sock_sendmsg', 'sock_sendmsg', 'security_socket_sendmsg', 'sock_sendmsg_nosec']
  logger.info("Try to attach multiple kernel functions to make sure the event can be triggered in most cases.")
  for event in event_list:
      try:
        b.attach_kprobe(event=event, fn_name="trace_sock_sendmsg")
      except Exception as exec:
        logger.info("Cannot attach kprobe to {}, it depends on your kernels.".format(event))

  # This operates on a table as defined in BPF via BPF_PERF_OUTPUT() [Defined in C code as imds_events, line 32], and
  # associates the callback Python function to be called when data is available in the perf ring buffer.
  b["imds_events"].open_perf_buffer(print_imds_event)

  # header
  print("Starting ImdsPacketAnalyzer...")
  print("Output format: Info Level:[INFO/ERROR...] IMDS version:[IMDSV1/2?] (pid:[pid]:[process name]:argv:[argv]) -> repeats 3 times for parent process")

  # filter and format output
  while 1:
    # Read messages from kernel pipe
    try:
      # This polls from all open perf ring buffers, calling the callback function that was provided when calling
      # open_perf_buffer for each entry.
      b.perf_buffer_poll()
    except ValueError:
      # Ignore messages from other tracers
      print("ValueError here")
      continue
    except KeyboardInterrupt:
      exit()
