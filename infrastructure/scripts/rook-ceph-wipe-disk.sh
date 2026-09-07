#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
	printf 'Usage: %s <node_name>\n' "$(basename "$0")" >&2
	exit 1
fi

node_name="$1"
pod_name="ceph-zap-${node_name}"

kubectl -n storage run "${pod_name}" \
	--rm -it \
	--restart=Never \
	--image=quay.io/ceph/ceph:v20.2.1 \
	--overrides="
{
  \"apiVersion\": \"v1\",
  \"spec\": {
    \"nodeName\": \"${node_name}\",
    \"hostNetwork\": true,
    \"containers\": [
      {
        \"name\": \"ceph-zap\",
        \"image\": \"quay.io/ceph/ceph:v20.2.1\",
        \"command\": [\"/bin/bash\"],
        \"stdin\": true,
        \"tty\": true,
        \"securityContext\": { \"privileged\": true },
        \"volumeMounts\": [
          { \"name\": \"dev\", \"mountPath\": \"/dev\" },
          { \"name\": \"run-udev\", \"mountPath\": \"/run/udev\" }
        ]
      }
    ],
    \"volumes\": [
      { \"name\": \"dev\", \"hostPath\": { \"path\": \"/dev\" } },
      { \"name\": \"run-udev\", \"hostPath\": { \"path\": \"/run/udev\" } }
    ]
  }
}"
