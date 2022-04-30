#!/usr/bin/env bash
set -e

API="https://api.digitalocean.com"
AUTH_HEADER=$(./_auth_header.sh)

DNS_NAME=$1
IP=$2
if [[ -z "$DNS_NAME" ]]; then
  >&2 echo "DNS_NAME is required"
  exit 1
fi

if [[ -z "$IP" ]]; then
  >&2 echo "IP is required"
  exit 1
fi

DNS_RECORD=$(echo "${DNS_NAME}" | sed -e 's/^\(.*\)\.\([0-9a-zA-Z]*\....\)$/\1/g')
DNS_ZONE=$(echo "${DNS_NAME}" | sed -e 's/^\(.*\)\.\([0-9a-zA-Z]*\....\)$/\2/g')

if [[ -z "$DNS_RECORD" ]]; then
  >&2 echo "Could not parse DNS record from DNS name ${DNS_NAME}"
  exit 2
fi

if [[ -z "$DNS_ZONE" ]]; then
  >&2 echo "Could not parse DNS zone from DNS name ${DNS_NAME}"
  exit 3
fi

if [[ "${DNS_RECORD}.${DNS_ZONE}" != "${DNS_NAME}" ]]; then
  >&2 echo "Unexpected parse for DNS name ${DNS_NAME}: ${DNS_RECORD}.${DNS_ZONE}"
  exit 4
fi

RECORDS=$(curl -s -X GET "${API}/v2/domains/${DNS_ZONE}/records" -H "${AUTH_HEADER}" | jq '.domain_records')
if [[ -z "${RECORDS}" || "${RECORDS}" == "null" ]]; then
  >&2 echo "Could not find domain ${DNS_ZONE} in Digital Ocean"
  exit 404
fi

POST_BODY=$(echo "{}" | \
              jq --arg v "A"              '. += {type: $v}' | \
              jq --arg v "${DNS_RECORD}"  '. += {name: $v}' | \
              jq --arg v "${IP}"          '. += {data: $v}' | \
              jq --argjson v "30"         '. += {ttl: $v}' | \
              jq -c )

EXISTING_RECORD=$(echo "$RECORDS" | jq ".[] | select (.name == \"${DNS_RECORD}\")")

if [[ -n "$EXISTING_RECORD" ]]; then
  EXISTING_ID=$(echo "$EXISTING_RECORD" | jq -r '.id')
  EXISTING_DATA=$(echo "$EXISTING_RECORD" | jq -r '.data')
  EXISTING_TYPE=$(echo "$EXISTING_RECORD" | jq -r '.type')
  EXISTING_TTL=$(echo "$EXISTING_RECORD" | jq -r '.ttl')
  echo "DNS Record ${DNS_NAME} (${EXISTING_ID}) already exists"
  
  if [[ "$EXISTING_TYPE" != "A" ]]; then
    >&2 echo "DNS Record is a ${EXISTING_TYPE} and not an A Record. Delete this record and try again." 
    exit 12
  fi

  if [[ "$EXISTING_DATA" == "$IP" ]]; then
    echo "DNS record already points to ${IP}. Skipping."
  else
    echo "DNS record points to ${EXISTING_DATA}; updating to ${IP}"

    RES=$(curl -s -X PUT "${API}/v2/domains/${DNS_ZONE}/records/${EXISTING_ID}" -H "${AUTH_HEADER}" \
          -H "Content-Type: application/json" \
          -d "$POST_BODY")
    
    echo "Sleeping ${EXISTING_TTL} seconds to wait for TTL to expire"
    sleep "${EXISTING_TTL}"
  fi
else
  echo "DNS record ${DNS_NAME} does not exist; creating it"
  RES=$(curl -s -X POST "${API}/v2/domains/${DNS_ZONE}/records" -H "${AUTH_HEADER}" \
          -H "Content-Type: application/json" \
          -d "$POST_BODY")
fi

