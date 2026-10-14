#!/bin/sh
set -eu

: "${ETCD_SNAPSHOT_DIR:?ETCD_SNAPSHOT_DIR not set}"
: "${ETCD_DB_DIR:?ETCD_DB_DIR not set}"

# Only restore when the datastore is empty, i.e. a freshly mounted tmpfs after boot.
# A populated datastore means k3s is being restarted with live data, so leave it alone.
if [ -d "$ETCD_DB_DIR" ] && [ -n "$(ls -A "$ETCD_DB_DIR" 2>/dev/null)" ]; then
  echo "datastore '$ETCD_DB_DIR' is not empty, nothing to restore"
  exit 0
fi

if [ -d "$ETCD_SNAPSHOT_DIR" ]; then
  LATEST_SNAPSHOT="$(find "$ETCD_SNAPSHOT_DIR" \
    -maxdepth 1 \
    -type f \
    -name 'etcd-snapshot-*' \
    -printf '%T@ %f\n' | sort -rn | head -n1 | cut -d' ' -f2-)"
else
  LATEST_SNAPSHOT=""
fi

if [ -z "$LATEST_SNAPSHOT" ]; then
  echo "no snapshots found in '$ETCD_SNAPSHOT_DIR', letting k3s bootstrap a fresh etcd"
  exit 0
fi

echo "using snapshot '$LATEST_SNAPSHOT'..."
k3s server \
  --cluster-reset \
  --cluster-reset-restore-path="${ETCD_SNAPSHOT_DIR}/${LATEST_SNAPSHOT}"
