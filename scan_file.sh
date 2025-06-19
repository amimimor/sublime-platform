#!/bin/bash

# This script submits a file to the sublime-rules-engine for scanning.

# 1. Create a test file
echo "Creating test file..."
cat << EOF > test_file.txt
This file contains the magic string: Hello, world!

hello world
EOF

# 2. Get the name of the strelka-frontend pod
echo "Finding strelka-frontend pod..."
FRONTEND_POD=$(kubectl get pods -l app.kubernetes.io/name=sublime-rules-engine-strelka-frontend -o jsonpath='{.items[0].metadata.name}' --namespace default)

if [ -z "$FRONTEND_POD" ]; then
    echo "Error: Could not find strelka-frontend pod."
    rm test_file.txt
    exit 1
fi
echo "Found pod: $FRONTEND_POD"

# 3. Port-forward to the pod in the background
echo "Setting up port-forwarding..."
kubectl port-forward "pod/$FRONTEND_POD" 56564:56564 --namespace default &
PORT_FORWARD_PID=$!

# Give the port-forwarding a moment to establish
sleep 3

# 4. Submit file directly via TCP as Strelka expects
echo "Submitting file for scanning..."
echo "Direct binary submission to Strelka frontend..."

# Method 1: Raw binary file
echo "Trying raw file upload..."
RESULT1=$(timeout 10 bash -c 'exec 3<>/dev/tcp/127.0.0.1/56564; cat test_file.txt >&3; shutdown 3 write; cat <&3; exec 3<&-' 2>/dev/null)

echo "Method 1 Response: '$RESULT1'"

# Method 2: With proper headers
echo "Trying with file size header..."  
FILE_SIZE=$(wc -c < test_file.txt)
RESULT2=$(timeout 10 bash -c 'exec 3<>/dev/tcp/127.0.0.1/56564; printf "%08x\n" '$FILE_SIZE' >&3; cat test_file.txt >&3; shutdown 3 write; cat <&3; exec 3<&-' 2>/dev/null)

echo "Method 2 Response: '$RESULT2'"

# Method 3: Simple HTTP POST
echo "Trying HTTP POST..."
RESULT3=$(curl -X POST --data-binary @test_file.txt -H "Content-Type: application/octet-stream" http://127.0.0.1:56564/scan 2>/dev/null)

echo "Method 3 Response: '$RESULT3'"

# Show best result
BEST_RESULT="$RESULT1"
if [ ! -z "$RESULT2" ] && [ "$RESULT2" != "@" ]; then
    BEST_RESULT="$RESULT2"
elif [ ! -z "$RESULT3" ] && [ "$RESULT3" != "@" ]; then
    BEST_RESULT="$RESULT3"
fi

echo ""
echo "Best Response:"
echo "$BEST_RESULT"
echo ""
echo "Attempting to parse as JSON:"
echo "$BEST_RESULT" | jq . 2>/dev/null || echo "Not JSON: $BEST_RESULT"

# 5. Clean up
echo "Cleaning up..."
kill $PORT_FORWARD_PID
rm test_file.txt

echo "Scan submission complete." 