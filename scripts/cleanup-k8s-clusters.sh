#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
##############################################################################
# Scans OpenStack for orphaned Kubernetes clusters
# Checks Jenkins URLs to avoid deleting clusters in active use
# Based on: global-jjb/shell/openstack-cleanup-orphaned-k8s-clusters.sh
##############################################################################

echo "---> Cleanup orphaned K8s clusters"

os_cloud="${OS_CLOUD:-vex}"
jenkins_urls="${JENKINS_URLS:-}"

set -eux -o pipefail

echo "INFO: Checking for orphaned K8s clusters on cloud: $os_cloud"

if [[ -z "$jenkins_urls" ]]; then
    echo "WARN: No Jenkins URLs provided, skipping cluster cleanup to be safe"
    exit 0
fi

echo "INFO: Will check Jenkins URLs for active builds: $jenkins_urls"

cluster_in_jenkins() {
    # Usage: cluster_in_jenkins CLUSTER_NAME JENKINS_URL [JENKINS_URL...]
    # Returns: 0 If CLUSTER_NAME is in Jenkins and 1 if CLUSTER_NAME is not in Jenkins.

    CLUSTER_NAME="${1}"

    builds=()
    for jenkins in "${@:2}"; do
        PARAMS="tree=computer[executors[currentExecutable[url]],"
        PARAMS=$PARAMS"oneOffExecutors[currentExecutable[url]]]"
        PARAMS=$PARAMS"&xpath=//url&wrapper=builds"
        JENKINS_URL="$jenkins/computer/api/json?$PARAMS"
        resp=$(curl -s -w "\\n\\n%{http_code}" --globoff -H "Content-Type:application/json" "$JENKINS_URL")
        json_data=$(echo "$resp" | head -n1)
        status=$(echo "$resp" | awk 'END {print $NF}')

        if [ "$status" != 200 ]; then
            >&2 echo "ERROR: Failed to fetch data from $JENKINS_URL with status code $status"
            >&2 echo "$resp"
            exit 1
        fi

        if [[ "${jenkins}" == *"jenkins."*".org" ]] || [[ "${jenkins}" == *"jenkins."*".io" ]]; then
            silo="production"
        else
            silo=$(echo "$jenkins" | sed 's/\/*$//' | awk -F'/' '{print $NF}')
        fi
        export silo
        # We purposely want to wordsplit here to combine the arrays
        # shellcheck disable=SC2206,SC2207
        builds=(${builds[@]} $(echo "$json_data" | \
            jq -r '.computer[].executors[].currentExecutable.url' \
            | grep -v null | awk -F'/' '{print ENVIRON["silo"] "-" $6 "-" $7}')
        )
    done

    if [[ "${builds[*]}" =~ $CLUSTER_NAME ]]; then
        return 0
    fi

    return 1
}

# Fetch coe cluster list
echo "INFO: Fetching COE cluster list from cloud: $os_cloud"
mapfile -t OS_COE_CLUSTERS < <(openstack --os-cloud "$os_cloud" coe cluster list \
            -f value -c "uuid" -c "name" -c "status" -c "health_status" \
            | awk '{print $2}')

echo "INFO: Found ${#OS_COE_CLUSTERS[@]} clusters"

# Search for COE clusters not in use by any active Jenkins systems and remove them.
deleted_count=0
for CLUSTER_NAME in "${OS_COE_CLUSTERS[@]}"; do
    # jenkins_urls intentionally needs globbing to be passed as separate params.
    # shellcheck disable=SC2153,SC2086
    if cluster_in_jenkins "$CLUSTER_NAME" $jenkins_urls; then
        echo "INFO: Cluster $CLUSTER_NAME is in use by active build, skipping"
        continue
    elif [[ "$CLUSTER_NAME" == *-managed-prod-k8s-* ]] || \
         [[ "$CLUSTER_NAME" == *-managed-test-k8s-* ]]; then
        echo "INFO: Not deleting managed cluster: $CLUSTER_NAME"
        continue
    else
        echo "INFO: Deleting orphaned k8s cluster: $CLUSTER_NAME"
        openstack --os-cloud "$os_cloud" coe cluster delete "$CLUSTER_NAME"
        ((deleted_count++))
    fi
done

echo "✅ K8s cluster cleanup complete - deleted $deleted_count orphaned cluster(s)"
