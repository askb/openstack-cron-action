#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
##############################################################################
# Scans OpenStack for orphaned stacks
# Checks Jenkins URLs to avoid deleting stacks in active use
##############################################################################

echo "---> Cleanup orphaned stacks"

os_cloud="${OS_CLOUD:-vex}"
jenkins_urls="${JENKINS_URLS:-}"

set -eux -o pipefail

echo "INFO: Checking for orphaned stacks on cloud: $os_cloud"

# Use lftools to cleanup orphaned stacks
if [[ -n "$jenkins_urls" ]]; then
    echo "INFO: Will check Jenkins URLs for active builds: $jenkins_urls"
    # lftools stack delete-stale takes jenkins URLs as positional arguments
    # shellcheck disable=SC2086
    lftools openstack --os-cloud "$os_cloud" stack delete-stale $jenkins_urls
else
    echo "WARN: No Jenkins URLs provided, skipping stack cleanup to be safe"
fi

echo "✅ Stack cleanup complete"
