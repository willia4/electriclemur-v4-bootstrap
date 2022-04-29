#!/usr/bin/env bash
set -e

API="https://api.digitalocean.com"
AUTH_HEADER=$(./_auth_header.sh)

DROPLET_ID=$1

if [[ -z "$DROPLET_ID" ]]; then
  >&2 "Droplet ID is required to fetch its status"
  exit 1
fi

DROPLET=$(curl -s -X GET "${API}/v2/droplets/${DROPLET_ID}" -H "${AUTH_HEADER}")

STATUS=$(echo "$DROPLET" | jq -r '.droplet.status')

if [[ -z "$STATUS" || "$STATUS" == "null" ]]; then
  >&2 echo "Could not find droplet status for droplet $DROPLET_ID"
  exit 404
fi

echo "${STATUS}"