#!/usr/bin/env bash
set -e
API="https://api.digitalocean.com"
AUTH_HEADER=$(./_auth_header.sh)

KEY_NAMES=$(./_get_secret.sh 'droplet_ssh_keys')

ALL_KEYS=$(curl -s -X GET "${API}/v2/account/keys?per_page=200" -H "${AUTH_HEADER}")
declare -a KEY_IDS

IFS=","

for k in ${KEY_NAMES}
do
  KEY_ID=$(echo "$ALL_KEYS" | jq ".ssh_keys[] | select(.name == \"${k}\") | .id")
  if [[ -z "$KEY_ID" ]]; then
    >&2 echo "Could not find SSH key ${k} in Digital Ocean"
    exit 404
  fi

  KEY_IDS+=("$KEY_ID")
done

R=""
NEED_COMMA=0

for id in ${KEY_IDS[@]}
do
  if [[ $NEED_COMMA == 1 ]]; then
    R="${R},"
  fi
  R="${R}${id}"
  NEED_COMMA=1
done

echo "[$R]"