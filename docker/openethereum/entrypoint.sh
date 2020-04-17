#!/bin/sh
PRIVATE_KEY_PATH="${VOLUME_PATH}${PRIVATE_KEY_PATH_SUFFIX}"

echo "$PRIVATE_KEY" | sed 's/^0x//' > $PRIVATE_KEY_PATH

./parity --base-path $VOLUME_PATH --config dev  --jsonrpc-interface all --jsonrpc-hosts="all" --jsonrpc-port=$PORT
