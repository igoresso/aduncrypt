#!/bin/sh

crond -b

echo "Checking Unbound configuration..."
unbound-checkconf /opt/unbound/unbound.conf
if [ $? -ne 0 ]; then
  echo "Unbound configuration is invalid: $?"
  exit 1
fi

if [ ! -f /var/lib/unbound/root.key ]; then
  echo "Bootstrapping the root trust anchor for DNSSEC validation..."
  unbound-anchor -a /var/lib/unbound/root.key
fi

echo "Setting correct permissions for AdGuard Home directories..."
chmod 700 /opt/adguardhome/work
chmod 700 /opt/adguardhome/conf

echo "Starting DNSCrypt-Proxy..."
dnscrypt-proxy -config /opt/dnscrypt/dnscrypt-proxy.toml &
if [ $? -ne 0 ]; then
  echo "Failed to start DNSCrypt-Proxy: $?"
  exit 1
fi

sleep 5

echo "Starting Unbound DNS resolver..."
unbound -d -c /opt/unbound/unbound.conf &
if [ $? -ne 0 ]; then
  echo "Failed to start Unbound: $?"
  exit 1
fi

echo "Starting AdGuard Home..."
exec /opt/adguardhome/AdGuardHome -c /opt/adguardhome/conf/AdGuardHome.yaml -w /opt/adguardhome/work --no-check-update
