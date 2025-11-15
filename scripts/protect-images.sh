#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
##############################################################################
# Protects OpenStack images that are currently in use
#
# This script marks images prefixed with "ZZCI - " as protected to prevent
# them from being purged by the image cleanup script.
##############################################################################

set -eu -o pipefail
echo "---> Protect in-use images"

os_cloud="${OS_CLOUD:-vex}"

# Get list of all CI-managed images (prefixed with "ZZCI - ")
mapfile -t images < <(openstack --os-cloud "$os_cloud" image list \
    -f value -c Name | grep "^ZZCI - " | sort -u)

if [[ ${#images[@]} -eq 0 ]]; then
    echo "INFO: No ZZCI images found to protect"
    exit 0
fi

echo "INFO: Found ${#images[@]} ZZCI images to check for protection"

for image in "${images[@]}"; do
    os_image_protected=$(openstack --os-cloud "$os_cloud" \
        image show "$image" -f value -c protected 2>/dev/null || echo "False")
    echo "Protected setting for $image: $os_image_protected"

    if [[ $os_image_protected != "True" ]]; then
        echo "    Image NOT set as protected, changing the protected value."
        openstack --os-cloud "$os_cloud" image set --protected "$image"
    fi
done

echo "✅ Image protection complete"
