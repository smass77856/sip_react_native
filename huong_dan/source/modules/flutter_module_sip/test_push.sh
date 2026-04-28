#!/bin/bash

# Script để test PushKit notification với JWT token
# Usage: ./test_push.sh <device_token> [payload_json]

DEVICE_TOKEN="${1:-c3ad0a464cc8bf989f67256657b437ad77c0c0229b566146e34f5ec719079024}"
PAYLOAD="${2:-{\"aps\":{\"alert\":\"test\",\"content-available\":1},\"callerId\":\"someCallerId1\",\"pushHint\":\"somehint\"}}"

# Generate JWT token
JWT_TOKEN=$(python3 /Volumes/ssd/Desktop/Sip/generate_jwt.py)

if [ -z "$JWT_TOKEN" ]; then
    echo "Error: Failed to generate JWT token"
    exit 1
fi

# Send push notification
curl --http2 -v \
  --header "authorization: bearer $JWT_TOKEN" \
  --header "apns-topic: com.idb.siprix.voip" \
  --header "apns-push-type: voip" \
  --header "apns-priority: 10" \
  --header "apns-expiration: 0" \
  --data "$PAYLOAD" \
  "https://api.sandbox.push.apple.com/3/device/$DEVICE_TOKEN"

