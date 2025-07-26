#!/bin/sh

crond -b

# Start Unbound
if [ ! -f /var/lib/unbound/root.key ]; then
  echo "Bootstrapping the root trust anchor for DNSSEC validation..."
  unbound-anchor -a /var/lib/unbound/root.key
fi

echo "Checking unbound configuration..."
unbound-checkconf /opt/unbound/unbound.conf
if [ $? -ne 0 ]; then
  echo "Unbound configuration is invalid: $?"
  exit 1
fi

echo "Starting Unbound DNS resolver..."
unbound -d -c /opt/unbound/unbound.conf &
if [ $? -ne 0 ]; then
  echo "Failed to start unbound: $?"
  exit 1
fi

# Start DNSCrypt-Proxy
echo "Starting DNSCrypt-Proxy..."
dnscrypt-proxy -config /opt/dnscrypt/dnscrypt-proxy.toml &
if [ $? -ne 0 ]; then
  echo "Failed to start dnscrypt-proxy: $?"
  exit 1
fi

sleep 5  # Wait for DNSCrypt-Proxy to initialize

# Start AdGuard Home
echo "Starting AdGuard Home..."
exec /opt/adguardhome/AdGuardHome -c /opt/adguardhome/conf/AdGuardHome.yaml -w /opt/adguardhome/work --no-check-update