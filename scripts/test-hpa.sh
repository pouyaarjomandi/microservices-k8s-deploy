#!/usr/bin/env bash
# Run k6 load test against the frontend to validate HPA scaling
# Usage: ./scripts/test-hpa.sh [namespace]

set -euo pipefail

NAMESPACE="${1:-dev}"
TEST_FILE="tests/k6/load-test.js"

# Check k6 is installed
if ! command -v k6 &> /dev/null; then
  echo "ERROR: k6 is not installed."
  echo "Install from: https://k6.io/docs/get-started/installation/"
  exit 1
fi

# Check the test file exists
if [[ ! -f "${TEST_FILE}" ]]; then
  echo "ERROR: Test file not found: ${TEST_FILE}"
  exit 1
fi

# Verify the namespace exists
if ! kubectl get namespace "${NAMESPACE}" &> /dev/null; then
  echo "ERROR: Namespace '${NAMESPACE}' does not exist."
  echo "Deploy first with: ./scripts/deploy-dev.sh"
  exit 1
fi

echo "==> Setting up port-forward to frontend in '${NAMESPACE}'..."
kubectl port-forward -n "${NAMESPACE}" svc/frontend 8080:8080 &
PF_PID=$!

# Cleanup port-forward on exit (even on Ctrl+C)
trap "kill ${PF_PID} 2>/dev/null || true" EXIT

# Wait for port-forward to be ready
sleep 3

echo "==> Running k6 load test..."
echo "==> In another terminal, watch HPA scaling with:"
echo "    kubectl get hpa -n ${NAMESPACE} -w"
echo ""

k6 run "${TEST_FILE}"

echo ""
echo "==> Load test complete. Final HPA state:"
kubectl get hpa -n "${NAMESPACE}"