# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

from src.imds_snoop import check_v2


def test_trivial_v1():
    payload = """GET /latest/meta-data/ HTTP/1.1
Host: 169.254.169.254
User-Agent: curl/7.79.1
Accept: */*"""

    assert(check_v2(payload) == False)
    
def test_trivial1_v2():
    payload = """PUT /latest/api/token HTTP/1.1
Host: 169.254.169.254
User-Agent: curl/7.79.1
Accept: */*
X-aws-ec2-metadata-token-ttl-seconds: 21600"""

    assert(check_v2(payload) == True)
    
def test_trivial2_v2():
    payload = """GET /latest/meta-data/ HTTP/1.1
Host: 169.254.169.254
User-Agent: curl/7.79.1
Accept: */*
X-aws-ec2-metadata-token: AQAEAPyADezUnSXUDdcpky8WuUyjVUDn-f0OKlwRU9bAd60vGWMx5w=="""

    assert(check_v2(payload) == True)