FROM alpine:latest
LABEL maintainer "publicarray"
ENV REVISION 0
LABEL org.label-schema.name="unbound"
LABEL org.label-schema.vendor="publicarray"
LABEL org.label-schema.description="Unbound is a validating, recursive, and caching DNS resolver."
LABEL org.label-schema.vcs-url="https://github.com/publicarray/dns-resolver-infra"
LABEL org.label-schema.version="1.7.1"
LABEL org.label-schema.license="MIT"

ENV UNBOUND_BUILD_DEPS expat-dev file gcc libevent-dev libressl-dev make musl-dev

RUN apk --no-cache add $UNBOUND_BUILD_DEPS

ARG UNBOUND_VERSION=1.7.2
ARG UNBOUND_SHA256=a85fc7bb34711992cf128b2012638ebb8dc1fe15818baa381f6489240845eaa0
ARG UNBOUND_DOWNLOAD_URL=https://www.unbound.net/downloads/unbound-${UNBOUND_VERSION}.tar.gz

RUN set -x && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    wget -O unbound.tar.gz $UNBOUND_DOWNLOAD_URL && \
    echo "${UNBOUND_SHA256} *unbound.tar.gz" | sha256sum -c - && \
    tar xzf unbound.tar.gz && \
    rm -f unbound.tar.gz && \
    cd unbound-${UNBOUND_VERSION} && \
    ./configure --with-conf-file=/etc/unbound/unbound.conf --with-run-dir=/etc/unbound \
    --with-pthreads --with-username=_unbound --with-libevent \
    CFLAGS="-O2 -flto -fPIE -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fstack-protector-strong -Wformat -Werror=format-security" \
    LDFLAGS="-Wl,-z,now -Wl,-z,relro" && \
    make install

#------------------------------------------------------------------------------#
FROM alpine:latest

ENV UNBOUND_RUN_DEPS expat libevent libressl runit shadow drill
RUN apk add --no-cache $UNBOUND_RUN_DEPS

COPY --from=0 /usr/local/sbin/unbound /usr/local/sbin/unbound
COPY --from=0 /usr/local/sbin/unbound-checkconf /usr/local/sbin/unbound-checkconf
COPY --from=0 /usr/local/sbin/unbound-control /usr/local/sbin/unbound-control
COPY --from=0 /usr/local/sbin/unbound-host /usr/local/sbin/unbound-host
COPY --from=0 /usr/local/sbin/unbound-anchor /usr/local/sbin/unbound-anchor
COPY --from=0 /usr/local/sbin/unbound-control-setup /usr/local/sbin/unbound-control-setup
COPY --from=0 /usr/local/lib/libunbound.so.2.5.10 /usr/local/lib/libunbound.so.2.5.10

RUN set -x && \
    cd /usr/local/lib/ && \
    ln -sf libunbound.so.2.5.10 libunbound.so.2 && \
    ln -sf libunbound.so.2.5.10 libunbound.so && \
    cd && \
    groupadd _unbound && \
    useradd -g _unbound -s /dev/null -d /dev/null _unbound && \
    mkdir -p /etc/service/unbound /etc/unbound/run && \
    unbound-anchor -a /etc/unbound/run/root.key || true && \
    chown _unbound:_unbound /etc/unbound/run && \
    chown _unbound:_unbound /etc/unbound/run/root.key && \
    wget -O /etc/unbound/root.hints https://www.internic.net/domain/named.root

COPY unbound.conf /etc/unbound/unbound.conf
COPY unbound.sh /etc/service/unbound/run
COPY entrypoint.sh /

EXPOSE 53/udp 53/tcp
EXPOSE 4949/tcp

RUN unbound -h || true

HEALTHCHECK --start-period=1m \
CMD ["drill", "-D", "-Q", ".", "@127.0.0.1", "SOA"]

ENTRYPOINT ["/entrypoint.sh"]
