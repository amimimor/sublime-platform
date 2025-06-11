#!/bin/bash

set -euo pipefail

# Find a strelka-frontend pod
FRONTEND_POD=$(kubectl get pods -n default -l "app.kubernetes.io/name=sublime-rules-engine-strelka-frontend" -o jsonpath='{.items[0].metadata.name}')
if [ -z "$FRONTEND_POD" ]; then
  echo "Error: Could not find a strelka-frontend pod."
  exit 1
fi

echo "Found strelka-frontend pod: $FRONTEND_POD"

# Port forward in the background
LOCAL_PORT=56564
echo "Port-forwarding $FRONTEND_POD from local port $LOCAL_PORT to container port 56564..."
kubectl port-forward -n default "pod/$FRONTEND_POD" "$LOCAL_PORT:56564" &
PORT_FORWARD_PID=$!

# Make sure the port-forward is killed on exit
trap "echo 'Killing port-forward process $PORT_FORWARD_PID'; kill $PORT_FORWARD_PID" EXIT

# Give the port-forward a moment to establish
sleep 2

# Submit the file
FILE_TO_SCAN="test_file.txt"
if [ ! -f "$FILE_TO_SCAN" ]; then
    echo "Error: Test file '$FILE_TO_SCAN' not found."
    exit 1
fi

echo "Submitting '$FILE_TO_SCAN' for scanning and watching backend logs..."

# Start watching the logs in the background
LOG_WATCH_PID=
(kubectl logs -n default -l "app.kubernetes.io/name=sublime-rules-engine-strelka-backend" --tail=10 -f > backend_logs.txt) &
LOG_WATCH_PID=$!

# Make sure the log watch is killed on exit
trap "echo 'Killing log watch process $LOG_WATCH_PID'; kill $LOG_WATCH_PID; echo 'Killing port-forward process $PORT_FORWARD_PID'; kill $PORT_FORWARD_PID" EXIT


# Submit the file
curl --http0.9 -s -X POST --data-binary "@$FILE_TO_SCAN" http://127.0.0.1:$LOCAL_PORT/scan > /dev/null

# Give logs a moment to propagate
sleep 5

# Stop the log watch
kill $LOG_WATCH_PID
trap "echo 'Killing port-forward process $PORT_FORWARD_PID'; kill $PORT_FORWARD_PID" EXIT

echo "Scan complete. Checking logs for matches..."

if grep -q "hello_world" backend_logs.txt; then
    echo "SUCCESS: Found 'hello_world' rule match in backend logs."
    cat backend_logs.txt
    rm backend_logs.txt
    exit 0
else
    echo "FAILURE: Did not find 'hello_world' rule match in backend logs."
    echo "Full logs from backend:"
    cat backend_logs.txt
    rm backend_logs.txt
    exit 1
fi 