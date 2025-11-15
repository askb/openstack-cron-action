#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
##############################################################################
# Scans OpenStack for orphaned ports and removes them
# Removes ports older than the configured age (default: 30 minutes)
##############################################################################

echo "---> Cleanup orphaned ports"

os_cloud="${OS_CLOUD:-vex}"
age="${PORT_CLEANUP_AGE:-30 minutes ago}"

set -eux -o pipefail

# Use lftools to cleanup old ports
lftools openstack --os-cloud "$os_cloud" port cleanup --age "$age"

echo "✅ Port cleanup complete"
