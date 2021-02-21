#!/bin/bash

set -e

REQIP="$(curl icanhazip.com)"

echo "URL=$URL"
echo "code=$CODE"
echo "name=$NAME"
echo "zone=$ZONE"
echo "La IP publica es:$REQIP"

export URI="$URL?code=$CODE&name=$NAME&zone=$ZONE&reqIP=$REQIP"

echo "$URI"

date
curl -X POST $URI -d "" 

echo
echo

exec "$@"

