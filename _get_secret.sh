#!/usr/bin/env bash
set -e

keyName=$1

if [[ -z "$keyName" ]]; then
  >&2 echo "ERROR: Attempted to retrieve empty secret key"
  exit 2
fi

V=$(cat ./secrets.json | jq -r ".${keyName}")
if [[ -z "$V" || "$V" == "null" ]]; then
  >&2 echo "ERROR: secrets.json must contain a value for \"${keyName}\""
  exit 3
fi

echo "$V"
exit 0