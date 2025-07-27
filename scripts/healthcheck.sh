#!/bin/sh

FILE=/opt/adguardhome/conf/AdGuardHome.yaml

if [ ! -f "$FILE" ]
then
   curl -q -s --connect-timeout 1 localhost:3000 > /dev/null && printf 'Waiting for config to be finished' || exit 1
elif PORT="$(grep '^bind_port:' "$FILE" | cut -f2 -d' ')" && ! curl -q --connect-timeout 1 "localhost:$PORT" > /dev/null 2>&1
then
    exit 1
fi
