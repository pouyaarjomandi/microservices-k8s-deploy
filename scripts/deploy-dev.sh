#!/usr/bin/env bash
# Deploy Online Boutique to the 'dev' namespace
# Usage: ./scripts/deploy-dev.sh

set -euo pipefail

NAMESPACE="dev"
RELEASE_NAME="boutique-dev"
CHART_PATH="charts/online-boutique-custom"
VALUES_FILE="${CHART_PATH}/values-dev.yaml"

if [[ ! -d "${CHART_PATH}" ]]; then
  echo "ERROR: Chart directory not found: ${CHART_PATH}"
  exit 1
fi
if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "ERROR: Values file not found: ${VALUES_FILE}"
  exit 1
fi

echo "==> Deploying Online Boutique to '${NAMESPACE}' namespace..."
helm upgrade --install "${RELEASE_NAME}" "${CHART_PATH}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  -f "${VALUES_FILE}"

echo "==> Waiting for all pods to be ready (timeout 300s)..."
kubectl wait --for=condition=Ready pod \
  -n "${NAMESPACE}" \
  -l app.kubernetes.io/instance="${RELEASE_NAME}" \
  --timeout=300s

echo "==> Deployment complete."
echo ""
echo "Pod status:"
kubectl get pods -n "${NAMESPACE}"
echo ""
echo "To access the frontend:"
echo "  kubectl port-forward -n ${NAMESPACE} svc/frontend 8080:8080"
echo "  Then open: http://localhost:8080"