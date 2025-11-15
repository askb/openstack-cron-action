#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
##############################################################################
# Scans OpenStack for orphaned volumes and removes them
##############################################################################

echo "---> Cleanup orphaned volumes"

os_cloud="${OS_CLOUD:-vex}"

set -eux -o pipefail

mapfile -t os_volumes < <(openstack --os-cloud "$os_cloud" volume list -f value -c ID --status Available)

if [[ ${#os_volumes[@]} -eq 0 ]]; then
    echo "No available volumes to delete"
else
    for volume in "${os_volumes[@]}"; do
        echo "Deleting volume: $volume"
        openstack --os-cloud "$os_cloud" volume delete "$volume"
    done
fi

echo "✅ Volume cleanup complete"
