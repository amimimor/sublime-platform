#!/bin/bash

set -euo pipefail

RELEASE_NAME="my-rules-engine"
NAMESPACE="default"
PVC_NAME="$RELEASE_NAME-sublime-rules-engine-persistent-storage"

echo "Uninstalling Helm release: $RELEASE_NAME..."
helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" --ignore-not-found=true

echo "Deleting PersistentVolumeClaim: $PVC_NAME..."
kubectl delete pvc "$PVC_NAME" --namespace "$NAMESPACE" --ignore-not-found=true

echo "Waiting for PVC to be fully terminated..."
while kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" &> /dev/null; do
  echo "PVC $PVC_NAME still exists. Waiting..."
  sleep 2
done

echo "Cleanup complete. PVC $PVC_NAME has been deleted." 