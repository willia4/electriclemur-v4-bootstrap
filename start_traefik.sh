#!/usr/bin/env bash
set -e

DROPLET_ID=$1
DROPLET_ADDRESS=$2
if [[ -z "$DROPLET_ID" ]]; then
  DROPLET_NAME=$(./_get_secret.sh 'droplet')
  DROPLET_ID=$(./_droplet_id.sh "${DROPLET_NAME}")
fi

if [[ -z "$DROPLET_ID" ]]; then
  >&2 echo "Droplet ID is required to restart traefik"
  exit 1
fi

if [[ -z "$DROPLET_ADDRESS" ]]; then
  DROPLET_ADDRESS=$(./_droplet_ip.sh "${DROPLET_ID}")
fi

if [[ -z "$DROPLET_ADDRESS" ]]; then
  >&2 echo "Droplet address is required to restart traefik"
  exit 1
fi

echo "Looking for running traefik containers..."
TRAEFIK_IDS=$(ssh "root@${DROPLET_ADDRESS}" "docker ps --filter 'name=traefik_frontend' -q")
echo "Found: ${TRAEFIK_IDS}"

if [[ -n "$TRAEFIK_IDS" ]]; then
  echo "traefik_frontend container already exists; removing it"
  ssh "root@${DROPLET_ADDRESS}" "docker rm --force traefik_frontend"
fi

echo "Starting traefik..."
ssh "root@${DROPLET_ADDRESS}" "docker run -d --name traefik_frontend --restart=always -e TRAEFIK_PROVIDERS_DOCKER=true -p 80:80 -p 443:443 -v /var/run/docker.sock:/var/run/docker.sock -v /volumes/traefik:/data traefik:v2.6.3"