# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import mock
from src.imds_snoop import get_proc_info

def test_trivial1():
    expected_argv = "/bin/bash ./makeCalls.sh"
    expected_proc_name = 'curl'
    expected_out = ":" + expected_proc_name + " argv:" + expected_argv
    
    with mock.patch("builtins.open",mock.mock_open(read_data=expected_argv)):
        assert(get_proc_info(1234,expected_proc_name) == expected_out)
        
        
#Testing erroneaous situations
error_message = " Unable to get argv information"

def test_io_error():
    open_mock = mock.mock_open()
    with mock.patch("builtins.open",open_mock):
        open_mock.side_effect = BlockingIOError
        assert(get_proc_info(123,'arb') == error_message)
        
def test_file_not_found():
    open_mock = mock.mock_open()
    with mock.patch("builtins.open",open_mock):
        open_mock.side_effect = FileNotFoundError
        assert(get_proc_info(123,'arb') == error_message)
        
def test_permission_error():
    open_mock = mock.mock_open()
    with mock.patch("builtins.open",open_mock):
        open_mock.side_effect = PermissionError
        assert(get_proc_info(123,'arb') == error_message)      

def test_unicode_error():
    open_mock = mock.mock_open()
    with mock.patch("builtins.open",open_mock):
        open_mock.side_effect = UnicodeError
        assert(get_proc_info(123,'arb') == error_message)

def test_unicode_decode():
    open_mock = mock.mock_open()
    with mock.patch("builtins.open",open_mock):
        open_mock.side_effect = UnicodeDecodeError
        assert(get_proc_info(123,'arb') == error_message)