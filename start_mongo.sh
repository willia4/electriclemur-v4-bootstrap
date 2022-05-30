#!/usr/bin/env bash
set -e

DROPLET_ID=$1
DROPLET_ADDRESS=$2
if [[ -z "$DROPLET_ID" ]]; then
  DROPLET_NAME=$(./_get_secret.sh 'droplet')
  DROPLET_ID=$(./_droplet_id.sh "${DROPLET_NAME}")
fi

if [[ -z "$DROPLET_ID" ]]; then
  >&2 echo "Droplet ID is required to restart mongo"
  exit 1
fi

if [[ -z "$DROPLET_ADDRESS" ]]; then
  DROPLET_ADDRESS=$(./_droplet_ip.sh "${DROPLET_ID}")
fi

if [[ -z "$DROPLET_ADDRESS" ]]; then
  >&2 echo "Droplet address is required to restart mongo"
  exit 1
fi

echo "Creating mongo data directory..."
ssh "root@${DROPLET_ADDRESS}" "mkdir -p /volumes/mongo"
ssh "root@${DROPLET_ADDRESS}" "chmod a+rwx /volumes/mongo"

echo "Looking for running mongo containers..."
MONGO_IDS=$(ssh "root@${DROPLET_ADDRESS}" "docker ps --filter 'name=mongo' -q")
echo "Found: ${MONGO_IDS}"

if [[ -n "$MONGO_IDS" ]]; then
  echo "mongo container already exists; removing it"
  ssh "root@${DROPLET_ADDRESS}" "docker rm --force mongo"
fi

MONGO_USER=$(./_get_secret.sh 'mongo_admin_user')
MONGO_PASSWORD=$(./_get_secret.sh 'mongo_admin_password')

CMD=""
CMD+="docker run -d --name mongo --restart=always "
CMD+="-e MONGO_INITDB_ROOT_USERNAME=${MONGO_USER} "
CMD+="-e MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASSWORD} "
CMD+="-v /volumes/mongo:/data/db "
CMD+="mongo:5.0 "

echo "Starting mongo..."
ssh "root@${DROPLET_ADDRESS}" "$CMD"