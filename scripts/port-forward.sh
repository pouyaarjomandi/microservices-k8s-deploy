#!/usr/bin/env bash
# Quick port-forward to the frontend service
# Usage: ./scripts/port-forward.sh [namespace]

set -euo pipefail

NAMESPACE="${1:-dev}"
LOCAL_PORT="8080"
SERVICE_PORT="8080"

# Verify the namespace exists
if ! kubectl get namespace "${NAMESPACE}" &> /dev/null; then
  echo "ERROR: Namespace '${NAMESPACE}' does not exist."
  exit 1
fi

# Verify frontend service exists
if ! kubectl get svc frontend -n "${NAMESPACE}" &> /dev/null; then
  echo "ERROR: Service 'frontend' not found in namespace '${NAMESPACE}'."
  echo "Deploy first with: ./scripts/deploy-dev.sh"
  exit 1
fi

echo "==> Port-forwarding frontend in namespace '${NAMESPACE}'..."
echo "==> Open http://localhost:${LOCAL_PORT} in your browser"
echo "==> Press Ctrl+C to stop"
echo ""

kubectl port-forward -n "${NAMESPACE}" svc/frontend "${LOCAL_PORT}:${SERVICE_PORT}"