#!/usr/bin/env bash
# Deploy Online Boutique to the 'prod' namespace
# Usage: ./scripts/deploy-prod.sh

set -euo pipefail

NAMESPACE="prod"
RELEASE_NAME="boutique-prod"
CHART_PATH="charts/online-boutique-custom"
VALUES_FILE="${CHART_PATH}/values-prod.yaml"

if [[ ! -d "${CHART_PATH}" ]]; then
  echo "ERROR: Chart directory not found: ${CHART_PATH}"
  exit 1
fi
if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "ERROR: Values file not found: ${VALUES_FILE}"
  exit 1
fi

echo "==> Deploying Online Boutique to '${NAMESPACE}' namespace..."
echo "==> This will use production values: HPA, NetworkPolicy, TLS, ..."

# Confirmation prompt for prod safety
read -rp "Are you sure you want to deploy to production? (yes/no): " CONFIRM
if [[ "${CONFIRM}" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

helm upgrade --install "${RELEASE_NAME}" "${CHART_PATH}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  -f "${VALUES_FILE}"

echo "==> Waiting for all pods to be ready (timeout 300s)..."
kubectl wait --for=condition=Ready pod \
  -n "${NAMESPACE}" \
  -l app.kubernetes.io/instance="${RELEASE_NAME}" \
  --timeout=300s

echo "==> Production deployment complete."
echo ""
echo "Resources:"
kubectl get all -n "${NAMESPACE}" -l app.kubernetes.io/instance="${RELEASE_NAME}"