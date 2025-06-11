#!/bin/bash

set -euo pipefail

CHART_NAME="sublime-rules-engine"
RELEASE_NAME="my-rules-engine"
NAMESPACE="default"

# Uninstall any existing release to ensure a clean slate
echo "Uninstalling any existing Helm release..."
helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" --no-hooks > /dev/null 2>&1 || true

# Get the chart version from Chart.yaml
CHART_VERSION=$(grep '^version:' "$CHART_NAME/Chart.yaml" | awk '{print $2}')

echo "Packaging Helm chart..."
helm package "$CHART_NAME" --destination . --version "$CHART_VERSION"

TGZ_NAME="$CHART_NAME-$CHART_VERSION.tgz"

# Clean up the tgz file on exit
trap "rm -f ./$TGZ_NAME" EXIT

echo "Deploying Helm chart..."
helm upgrade --install "$RELEASE_NAME" "./$TGZ_NAME" --namespace "$NAMESPACE" --wait --timeout 5m

echo "Deployment successful! All pods are ready." 