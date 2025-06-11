#!/bin/bash

set -euo pipefail

CHART_NAME="sublime-rules-engine"
RELEASE_NAME="my-rules-engine"
NAMESPACE="default"

# Get the chart version from Chart.yaml
CHART_VERSION=$(grep '^version:' "$CHART_NAME/Chart.yaml" | awk '{print $2}')

echo "Packaging Helm chart..."
helm package "$CHART_NAME" --destination . --version "$CHART_VERSION"

TGZ_NAME="$CHART_NAME-$CHART_VERSION.tgz"

echo "Deploying Helm chart..."
helm install "$RELEASE_NAME" "./$TGZ_NAME" --namespace "$NAMESPACE" --wait

echo "Deployment successful!" 