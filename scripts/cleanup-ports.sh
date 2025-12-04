#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
##############################################################################
# Scans OpenStack for orphaned ports and removes them
# Removes ports older than the configured age (default: 30 minutes)
# Based on: global-jjb/shell/openstack-cleanup-orphaned-ports.sh
##############################################################################

echo "---> Cleanup orphaned ports"

os_cloud="${OS_CLOUD:-vex}"
age="${PORT_CLEANUP_AGE:-30 minutes ago}"

set -eu -o pipefail

tmpfile=$(mktemp --suffix -openstack-ports.txt)
cores=$(nproc --all)
threads=$((3*cores))
regex_created_at='^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})Z$'

# Set cutoff time for deletion
cutoff=$(date -d "$age" +%s)

_cleanup()
{
    uuid=$1
    created_at=$(openstack --os-cloud "$os_cloud" port show -f value -c created_at "$uuid")

    if [ "$created_at" == "None" ]; then
        echo "No value for port creation time; skipping: $uuid"

    elif echo "$created_at" | grep -qP "$regex_created_at"; then

        created_at_uxts=$(date -d "$created_at" +"%s")

        # Cleanup objects where created_at is older than specified cutoff time
        if [[ "$created_at_uxts" -lt "$cutoff" ]]; then
            echo "Removing orphaned port $uuid created $created_at_uxts > $age"
            openstack --os-cloud "$os_cloud" port delete "$uuid"
        fi
    else
        echo "Unknown/unexpected value for created_at: ${created_at}"
    fi
}

_rmtemp()
{
    if [ -f "$tmpfile" ]; then
        rm -f "$tmpfile"
    fi
}

trap _rmtemp EXIT

# Output the initial list of port UUIDs to a temporary file
openstack --os-cloud "$os_cloud" port list -f value -c ID -c status \
    | { grep -e DOWN || true; } | { awk '{print $1}' || true; } > "$tmpfile"

# Count the number to process
total=$(wc -l "$tmpfile" | awk '{print $1}')

if [ "$total" -eq 0 ]; then
    echo "No orphaned ports to process."
    exit 0
fi

echo "Ports to process: $total; age limit: $cutoff"
echo "Using $threads parallel processes..."

# Export variables and send to parallel for processing
export -f _cleanup
export os_cloud cutoff age regex_created_at
parallel --progress --retries 3 -j "$threads" _cleanup < "$tmpfile"

echo "✅ Port cleanup complete"
