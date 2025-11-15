#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
##############################################################################
# Scans OpenStack for orphaned Kubernetes clusters
# Checks Jenkins URLs to avoid deleting clusters in active use
##############################################################################

echo "---> Cleanup orphaned K8s clusters"

os_cloud="${OS_CLOUD:-vex}"
jenkins_urls="${JENKINS_URLS:-}"

set -eux -o pipefail

echo "INFO: Checking for orphaned K8s clusters on cloud: $os_cloud"

# Use lftools to cleanup orphaned k8s clusters
if [[ -n "$jenkins_urls" ]]; then
    echo "INFO: Will check Jenkins URLs for active builds: $jenkins_urls"
    lftools openstack --os-cloud "$os_cloud" cluster cleanup --jenkins "$jenkins_urls"
else
    echo "WARN: No Jenkins URLs provided, skipping cluster cleanup to be safe"
fi

echo "✅ K8s cluster cleanup complete"
