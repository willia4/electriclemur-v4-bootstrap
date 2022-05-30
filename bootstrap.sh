#!/usr/bin/env bash
set -e

API="https://api.digitalocean.com"

AUTH_HEADER=$(./_auth_header.sh)

DROPLET_NAME=$(./_get_secret.sh 'droplet')
DROPLET_REGION=$(./_get_secret.sh 'droplet_region')
DROPLET_SIZE=$(./_get_secret.sh 'droplet_size')
DROPLET_IMAGE=$(./_get_secret.sh 'droplet_image')
DROPLET_KEYS=$(./_get_keys.sh)
DNS_HOSTNAME=$(./_get_secret.sh 'dns_hostname')

DROPLET_ID=$(./_droplet_id.sh "${DROPLET_NAME}")

if [[ -z "$DROPLET_ID" ]]; then
  DROPLET_EXISTED=0
  echo "Droplet ${DROPLET_NAME} could not be found. Creating..."

  DROPLET_POST_BODY=$(echo "{}" | \
                      jq --arg v "${DROPLET_NAME}"    '. += {name: $v}' | \
                      jq --arg v "${DROPLET_REGION}"  '. += {region: $v}' | \
                      jq --arg v "${DROPLET_SIZE}"    '. += {size: $v}' | \
                      jq --arg v "${DROPLET_IMAGE}"    '. += {image: $v}' | \
                      jq --argjson v "${DROPLET_KEYS}" '. += {ssh_keys: $v}' | \
                      jq --argjson v "true" '. += {with_droplet_agent: $v}' | \
                      jq -c)

  RES=$(curl -s -X POST "${API}/v2/droplets" -H "${AUTH_HEADER}" \
        -H "Content-Type: application/json" \
        -d "$DROPLET_POST_BODY")
  DROPLET_ID=$(echo "$RES" | jq -r '.droplet.id')
  echo "Created droplet with id: ${DROPLET_ID}"
else
  DROPLET_EXISTED=1
  echo "Found existing droplet with id: ${DROPLET_ID}"
fi

MAX_TIMEOUT=$((5 * 60))
TIMEOUT=$(($(date +"%s") + $MAX_TIMEOUT))
DROPLET_STATUS=$(./_droplet_status.sh "$DROPLET_ID")

while [[ "$DROPLET_STATUS" != "active" && $(date +"%s") < $TIMEOUT ]]
do
  echo "Waiting for droplet..."
  sleep 15
  DROPLET_STATUS=$(./_droplet_status.sh "$DROPLET_ID")
done

if [[ "$DROPLET_STATUS" != "active" ]]; then
  >&2 echo "Droplet with id ${DROPLET_ID} never became active"
  exit 5
fi

if [[ "$DROPLET_EXISTED" = "0" ]]; then
  # just because the droplet says it's ready doesn't mean it's actually ready; so we can wait for another 30 seconds to give it time 
  echo "Waiting for droplet..."
  sleep 15
  echo "Waiting for droplet..."
  sleep 15
fi

echo "Droplet with id ${DROPLET_ID} is ready"
DROPLET_ADDRESS=$(./_droplet_ip.sh "${DROPLET_ID}")
echo "Droplet has public IP: ${DROPLET_ADDRESS}"

./_update_dns.sh "$DNS_HOSTNAME" "$DROPLET_ADDRESS"

echo "Connecting to host via SSH; you may need to approve the host fingerprint"
SSH_HOST=$(ssh "root@${DROPLET_ADDRESS}" hostname)
if [[ "$SSH_HOST" != "$DROPLET_NAME" ]]; then
  >&2 echo "SSH Host ${SSH_HOST} does not match the droplet name ${DROPLET_NAME}"
  exit 6
fi

echo "Updating apt..."
ssh "root@${DROPLET_ADDRESS}" apt-get update

echo "Installing docker pre-reqs..."
ssh "root@${DROPLET_ADDRESS}" apt-get install -y ca-certificates curl gnupg lsb-release

echo "Adding Docker's GPG Key..."
ssh "root@${DROPLET_ADDRESS}" "rm -f /usr/share/keyrings/docker-archive-keyring.gpg"
ssh "root@${DROPLET_ADDRESS}" "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"

echo "Adding Docker's stable repository..."
ssh "root@${DROPLET_ADDRESS}" "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"

echo "Updating apt..."
ssh "root@${DROPLET_ADDRESS}" apt-get update

echo "Installing docker..."
ssh "root@${DROPLET_ADDRESS}" apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "Creating traefik data directory..."
ssh "root@${DROPLET_ADDRESS}" "mkdir -p /volumes/traefik"
ssh "root@${DROPLET_ADDRESS}" "chmod -R a+rwx /volumes/traefik"

./start_traefik.sh

./start_mongo.sh