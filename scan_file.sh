#!/bin/bash

# This script submits a file to the sublime-rules-engine for scanning.

# 1. Create a test file
echo "Creating test file..."
echo "hello world" > test.txt

# 2. Get the name of the strelka-frontend pod
echo "Finding strelka-frontend pod..."
FRONTEND_POD=$(kubectl get pods -l app.kubernetes.io/name=sublime-rules-engine-strelka-frontend -o jsonpath='{.items[0].metadata.name}' --namespace default)

if [ -z "$FRONTEND_POD" ]; then
    echo "Error: Could not find strelka-frontend pod."
    rm test.txt
    exit 1
fi
echo "Found pod: $FRONTEND_POD"

# 3. Port-forward to the pod in the background
echo "Setting up port-forwarding..."
kubectl port-forward "pod/$FRONTEND_POD" 56564:56564 --namespace default &
PORT_FORWARD_PID=$!

# Give the port-forwarding a moment to establish
sleep 3

# 4. Submit the file using curl
echo "Submitting file for scanning..."
curl --http0.9 -X POST --data-binary @test.txt http://127.0.0.1:56564

# 5. Clean up
echo "Cleaning up..."
kill $PORT_FORWARD_PID
rm test.txt

echo "Scan submission complete." 