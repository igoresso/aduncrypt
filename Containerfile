FROM alpine:latest

ARG AGH_VER=v0.107.63
ARG TARGETARCH
ARG TARGETVARIANT

# Install packages
RUN apk --no-cache add ca-certificates libcap tzdata unbound dnscrypt-proxy bind-tools && \
	mkdir -p /opt/adguardhome/conf /opt/adguardhome/work && \
	chown -R nobody:nogroup /opt/adguardhome

# Copy files
COPY unbound/unbound.conf /opt/unbound/unbound.conf

# Authoritative root hints for unbound
RUN mkdir -p /etc/crontabs /var/lib/unbound \
	&& wget -qO /var/lib/unbound/root.hints https://www.internic.net/domain/named.root \
	&& chown unbound:unbound /var/lib/unbound/root.hints
COPY unbound/hints-cron /etc/crontabs/root

# Setup DNSCrypt-Proxy
COPY dnscrypt/dnscrypt-proxy.toml /opt/dnscrypt/dnscrypt-proxy.toml

# Install AdGuard Home and set up entrypoint
RUN wget https://github.com/AdguardTeam/AdGuardHome/releases/download/${AGH_VER}/AdGuardHome_linux_${TARGETARCH}${TARGETVARIANT}.tar.gz >/dev/null 2>&1 \
	&& mkdir -p /opt/adguardhome/conf /opt/adguardhome/work \
	&& tar xf AdGuardHome_linux_${TARGETARCH}${TARGETVARIANT}.tar.gz ./AdGuardHome/AdGuardHome  --strip-components=2 -C /opt/adguardhome \
	&& chown nobody:nogroup /opt/adguardhome/AdGuardHome \
	&& setcap 'CAP_NET_BIND_SERVICE=+eip' /opt/adguardhome/AdGuardHome \
	&& rm -rf /tmp/* /var/cache/apk/*

# Copy healthcheck and entrypoint scripts
COPY scripts/ /opt/scripts/

WORKDIR /opt

VOLUME ["/opt/adguardhome/conf", "/opt/adguardhome/work", "/opt/unbound", "/opt/dnscrypt"]

EXPOSE 53/tcp 53/udp \
	67/udp \
	68/udp \
	80/tcp \
	443/tcp 443/udp \
	853/tcp 853/udp \
	3000/tcp 3000/udp \
	5443/tcp 5443/udp \
	6060/tcp

HEALTHCHECK --interval=30s --timeout=15s --start-period=5s CMD sh /opt/scripts/healthcheck.sh

CMD ["/opt/scripts/entrypoint.sh"]