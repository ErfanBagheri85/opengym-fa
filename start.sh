#!/bin/sh
set -e
export DATA_DIR="${DATA_DIR:-/app/data}"
mkdir -p "$DATA_DIR"
cd /app/api
PORT=3000 npm start &
exec nginx -g "daemon off;"
