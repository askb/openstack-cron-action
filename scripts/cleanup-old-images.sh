#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
##############################################################################
# Removes OpenStack images older than X days in the cloud
##############################################################################
echo "---> Cleanup old images"

os_cloud="${OS_CLOUD:-vex}"
os_image_cleanup_age="${OS_IMAGE_CLEANUP_AGE:-30}"

set -eux -o pipefail

lftools openstack --os-cloud "${os_cloud}" image cleanup --days="${os_image_cleanup_age}"
