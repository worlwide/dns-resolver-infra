#!/bin/sh
set -e

getServiceIP () {
    nslookup "$1" 2>/dev/null | grep -oE '(([0-9]{1,3})\.){3}(1?[0-9]{1,3})'
}

UNBOUND_SERVICE_HOST=${UNBOUND_SERVICE_HOST-"1.1.1.1"}
UNBOUND_SERVICE_PORT=${UNBOUND_SERVICE_PORT-"53"}
if [ -n "$(getServiceIP unbound)" ]; then
    UNBOUND_SERVICE_HOST=$(getServiceIP unbound)
fi
export RESOLVER="$UNBOUND_SERVICE_HOST:$UNBOUND_SERVICE_PORT"

DOH_PROXY_SERVICE_HOST=${DOH_PROXY_SERVICE_HOST-"127.0.0.1"}
DOH_PROXY_SERVICE_PORT=${DOH_PROXY_SERVICE_PORT-"3000"}
if [ -n "$(getServiceIP doh-proxy)" ]; then
    DOH_PROXY_SERVICE_HOST=$(getServiceIP doh-proxy)
fi
export DOH_SERVER="$DOH_PROXY_SERVICE_HOST:$DOH_PROXY_SERVICE_PORT"

sed -i -e "s/server doh-proxy .*/server doh-proxy ${DOH_SERVER}/" \
    -e "s/server dns .*/server dns ${RESOLVER}/" \
    /etc/haproxy.conf

if [ $# -eq 0 ]; then
    exec /usr/local/sbin/haproxy -V -f /etc/haproxy.conf # [-de] single threaded - poll is likely faster then epoll
fi
# /usr/local/sbin/haproxy -D -V -f /etc/haproxy.conf

[ "$1" = '--' ] && shift
exec "$@"
