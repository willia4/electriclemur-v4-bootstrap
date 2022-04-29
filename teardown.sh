#!/usr/bin/env bash
set -e

API="https://api.digitalocean.com"

AUTH_HEADER=$(./_auth_header.sh)
DROPLET_NAME=$(./_get_secret.sh 'droplet')

DROPLET_ID=$(./_droplet_id.sh "$DROPLET_NAME")

if [[ -z "$DROPLET_ID" ]]; then
  echo "Droplet ${DROPLET_NAME} could not be found. Nothing to tear down."
  exit 0
fi

echo "Deleting droplet ${DROPLET_NAME}"
curl -s -X DELETE "${API}/v2/droplets/${DROPLET_ID}" -H "${AUTH_HEADER}"