#!/usr/bin/env bash
# Clean up application releases and namespaces
# Usage: ./scripts/clean.sh [dev|prod|all]

set -euo pipefail

TARGET="${1:-dev}"

cleanup_release() {
  local namespace="$1"
  local release="$2"

  if helm status "${release}" -n "${namespace}" &> /dev/null; then
    echo "==> Uninstalling ${release} from ${namespace}..."
    helm uninstall "${release}" -n "${namespace}"
  else
    echo "==> Release ${release} not found in ${namespace}, skipping."
  fi

  if kubectl get namespace "${namespace}" &> /dev/null; then
    echo "==> Deleting namespace ${namespace}..."
    kubectl delete namespace "${namespace}"
  fi
}

case "${TARGET}" in
  dev)
    cleanup_release "dev" "boutique-dev"
    ;;
  prod)
    cleanup_release "prod" "boutique-prod"
    ;;
  all)
    cleanup_release "dev"  "boutique-dev"
    cleanup_release "prod" "boutique-prod"
    ;;
  *)
    echo "Usage: $0 [dev|prod|all]"
    exit 1
    ;;
esac

echo "==> Cleanup complete."
echo ""
echo "Note: Cluster addons (ingress-nginx, cert-manager) NOT removed."
echo "To remove them:"
echo "  helm uninstall ingress-nginx -n ingress-nginx"
echo "  helm uninstall cert-manager -n cert-manager"