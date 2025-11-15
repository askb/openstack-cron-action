#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
##############################################################################
# Scans OpenStack for orphaned servers/instances
# Checks Jenkins URLs to avoid deleting servers in active use
##############################################################################

echo "---> Cleanup orphaned servers"

os_cloud="${OS_CLOUD:-vex}"
jenkins_urls="${JENKINS_URLS:-}"

set -eux -o pipefail

echo "INFO: Checking for orphaned servers on cloud: $os_cloud"

# Use lftools to cleanup orphaned servers
# lftools will check Jenkins if URLs are provided
if [[ -n "$jenkins_urls" ]]; then
    echo "INFO: Will check Jenkins URLs for active builds: $jenkins_urls"
    lftools openstack --os-cloud "$os_cloud" server cleanup --jenkins "$jenkins_urls"
else
    echo "WARN: No Jenkins URLs provided, skipping server cleanup to be safe"
fi

echo "✅ Server cleanup complete"
