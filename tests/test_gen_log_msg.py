# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

from src.imds_snoop import gen_log_msg
from event_proto import Event
import mock

#prortype obj for tests
event = Event()

def my_open(filename):
    if filename == '/proc/1/cmdline':
        content = 'test1'
    elif filename == '/proc/2/cmdline':
        content = 'test2'
    elif filename == '/proc/3/cmdline':
        content = 'test3'
    elif filename == '/proc/4/cmdline':
        content = 'test4'
    else:
        raise FileNotFoundError(filename)
    file_object = mock.mock_open(read_data=content).return_value
    file_object.__iter__.return_value = content.splitlines(True)
    return file_object


def test_single_file():
    with mock.patch("builtins.open",mock.mock_open(read_data='test')):
        assert(gen_log_msg(False,Event()) == 'IMDSv1(!) (pid:1:curl argv:test) called by -> (pid:2:zsh argv:test) -> (pid:3:sshd argv:test) -> (pid:3:sshd argv:test)')
    
def test_multiple_files():
    with mock.patch("builtins.open",my_open):
        assert(gen_log_msg(False,Event()) == 'IMDSv1(!) (pid:1:curl argv:test1) called by -> (pid:2:zsh argv:test2) -> (pid:3:sshd argv:test3) -> (pid:3:sshd argv:test4)')

        
#Testing erroneaous situations
expected_out = "IMDSv1(!) (pid:1 Unable to get argv information) called by -> (pid:2 Unable to get argv information) -> (pid:3 Unable to get argv information) -> (pid:3 Unable to get argv information)"

def test_io_error():
    open_mock = mock.mock_open()
    with mock.patch("builtins.open",open_mock):
        open_mock.side_effect = BlockingIOError
        assert(gen_log_msg(False,Event()) == expected_out)
        
def test_file_not_found():
    open_mock = mock.mock_open()
    with mock.patch("builtins.open",open_mock):
        open_mock.side_effect = FileNotFoundError
        assert(gen_log_msg(False,Event()) == expected_out)
        
def test_permission_error():
    open_mock = mock.mock_open()
    with mock.patch("builtins.open",open_mock):
        open_mock.side_effect = PermissionError
        assert(gen_log_msg(False,Event()) == expected_out)     

def test_unicode_error():
    open_mock = mock.mock_open()
    with mock.patch("builtins.open",open_mock):
        open_mock.side_effect = UnicodeError
        assert(gen_log_msg(False,Event()) == expected_out)

def test_unicode_decode():
    open_mock = mock.mock_open()
    with mock.patch("builtins.open",open_mock):
        open_mock.side_effect = UnicodeDecodeError
        assert(gen_log_msg(False,Event()) == expected_out)