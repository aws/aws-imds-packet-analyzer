#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

python3 -m pytest tests/ -v
rm -r .pytest_cache
rm -r src/__pycache__
rm -r tests/__pycache__