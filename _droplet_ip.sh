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

IP=$(echo "$DROPLET" | jq -r '.droplet.networks.v4[] | select (.type == "public") | .ip_address')

if [[ -z "$IP" || "$IP" == "null" ]]; then
  >&2 echo "Could not find droplet IP for droplet $DROPLET_ID"
  exit 404
fi

echo "${IP}"