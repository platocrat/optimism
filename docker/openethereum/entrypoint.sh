#!/bin/sh
./parity --config rollup-fullnode.toml --min-gas-price 0 --reseal-min-period 0 --jsonrpc-port=$PORT
