#!/usr/bin/env bash
# Install or upgrade cert-manager and apply ClusterIssuers
# Usage: ./scripts/install-cert-manager.sh

set -euo pipefail

NAMESPACE="cert-manager"
RELEASE_NAME="cert-manager"
VALUES_FILE="cluster-addons/cert-manager/values.yaml"
ISSUER_FILE="cluster-addons/cert-manager/cluster-issuer.yaml"

if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "ERROR: Values file not found: ${VALUES_FILE}"
  exit 1
fi
if [[ ! -f "${ISSUER_FILE}" ]]; then
  echo "ERROR: ClusterIssuer file not found: ${ISSUER_FILE}"
  exit 1
fi

echo "==> Installing/upgrading cert-manager in namespace '${NAMESPACE}'..."
helm upgrade --install "${RELEASE_NAME}" oci://quay.io/jetstack/charts/cert-manager \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  -f "${VALUES_FILE}"

echo "==> Waiting for cert-manager components to be ready..."
kubectl wait --for=condition=Available \
  deployment/cert-manager \
  -n "${NAMESPACE}" \
  --timeout=120s
kubectl wait --for=condition=Available \
  deployment/cert-manager-webhook \
  -n "${NAMESPACE}" \
  --timeout=120s
kubectl wait --for=condition=Available \
  deployment/cert-manager-cainjector \
  -n "${NAMESPACE}" \
  --timeout=120s

echo "==> Applying ClusterIssuer manifests..."
kubectl apply -f "${ISSUER_FILE}"

echo "==> cert-manager installed successfully."
echo ""
echo "ClusterIssuers:"
kubectl get clusterissuers