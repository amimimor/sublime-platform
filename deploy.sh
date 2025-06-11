#!/bin/bash

set -euo pipefail

CHART_NAME="sublime-rules-engine"
RELEASE_NAME="my-rules-engine"
NAMESPACE="default"
PVC_NAME="$RELEASE_NAME-sublime-rules-engine-persistent-storage"

# Check if the PVC exists and delete it if it does
if kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" &> /dev/null; then
  echo "PersistentVolumeClaim $PVC_NAME already exists. Deleting it now..."
  kubectl delete pvc "$PVC_NAME" --namespace "$NAMESPACE"
  echo "Waiting for PVC to be fully terminated..."
  while kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" &> /dev/null; do
    echo "PVC $PVC_NAME still exists. Waiting..."
    sleep 2
  done
  echo "PVC $PVC_NAME has been deleted."
fi

# Get the chart version from Chart.yaml
CHART_VERSION=$(grep '^version:' "$CHART_NAME/Chart.yaml" | awk '{print $2}')

echo "Packaging Helm chart..."
helm package "$CHART_NAME" --destination . --version "$CHART_VERSION"

TGZ_NAME="$CHART_NAME-$CHART_VERSION.tgz"

# Clean up the tgz file on exit
trap "rm -f ./$TGZ_NAME" EXIT

echo "Deploying Helm chart..."
helm upgrade --install "$RELEASE_NAME" "./$TGZ_NAME" --namespace "$NAMESPACE" --wait

echo "Deployment successful!" 