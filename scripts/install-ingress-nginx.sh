#!/usr/bin/env bash
# Install or upgrade NGINX Ingress Controller
# Usage: ./scripts/install-ingress-nginx.sh

set -euo pipefail

NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"
VALUES_FILE="cluster-addons/ingress-nginx/values.yaml"

if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "ERROR: Values file not found: ${VALUES_FILE}"
  exit 1
fi

echo "==> Adding Helm repository for ingress-nginx..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update ingress-nginx

echo "==> Installing/upgrading ingress-nginx in namespace '${NAMESPACE}'..."
helm upgrade --install "${RELEASE_NAME}" ingress-nginx/ingress-nginx \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  -f "${VALUES_FILE}"

echo "==> Waiting for controller to be ready (timeout 120s)..."
kubectl wait --for=condition=Available \
  deployment/ingress-nginx-controller \
  -n "${NAMESPACE}" \
  --timeout=120s

echo "==> ingress-nginx installed successfully."
echo ""
echo "Service status:"
kubectl get svc -n "${NAMESPACE}"