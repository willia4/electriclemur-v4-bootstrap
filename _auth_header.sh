#!/usr/bin/env bash
set -e

KEY=$(./_get_secret.sh 'digital_ocean_api_key')
AUTH_HEADER="Authorization: Bearer ${KEY}"

echo "$AUTH_HEADER"