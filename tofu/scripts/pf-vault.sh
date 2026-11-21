#!/bin/sh
#
# 'pf-vault.sh' switches up or down the port-forwarding of 'vault.vault.svc'
#
# It simply runs `kubectl -n vault port-forward svc/vault 8200:8200`, saves the
# PID in a temporary file ($PIDFILE) and if it exists kills it. It is used as a
# Terragrunt hook for configuring the deployed Vault instance.
#
# Usage:
#   ./pf-vault.sh <up|down>

set -eu

PIDFILE=/tmp/sanae-vault-pf.pid
ACTION=$1

if [ -f "${PIDFILE}" -o "${ACTION}" = "down" ]; then
  kill "$(cat ${PIDFILE} 2>/dev/null)" 2>/dev/null || true
  rm "${PIDFILE}" 2>/dev/null || true
  if [ "${ACTION}" != "up" ]; then
    exit 0
  fi
fi

kubectl -n vault port-forward svc/vault 8200:8200 >/dev/null 2>&1 &
echo $! > "${PIDFILE}"

i=1
while [ "$i" -le 30 ]; do
  if curl -fsS http://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
    exit 0
  fi
  sleep 0.2
  i=$((i + 1))
done

echo "error: vault port-forward did not become ready"
exit 1
