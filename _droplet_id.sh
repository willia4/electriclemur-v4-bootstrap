#!/usr/bin/env bash
set -e

API="https://api.digitalocean.com"
AUTH_HEADER=$(./_auth_header.sh)

DROPLET_NAME=$1

if [[ -z "$DROPLET_NAME" ]]; then
  >&2 "Droplet Name is required to fetch its ID"
  exit 1
fi

DROPLETS=$(curl -s -X GET "https://api.digitalocean.com/v2/droplets" -H "${AUTH_HEADER}")
DROPLET_ID=$(echo "$DROPLETS" | jq -r ".droplets[] | select(.name == \"${DROPLET_NAME}\") | .id")

if [[ DROPLET_ID == "null" ]]; then
  DROPLET_ID=""
fi

echo "${DROPLET_ID}"