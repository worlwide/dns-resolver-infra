FROM alpine:latest
LABEL maintainer "publicarray"
LABEL description "A DNS-over-HTTP server proxy in Rust. https://github.com/jedisct1/rust-doh"
ENV REVISION 1

ENV DOH_BUILD_DEPS rust cargo git

RUN apk add --no-cache $DOH_BUILD_DEPS
# RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

# RUN cargo install doh-proxy --root /usr/local/
RUN set -x && \
    cd /tmp && \
    git clone https://github.com/jedisct1/rust-doh && \
    cd rust-doh && \
    cargo build --release && \
    cp target/release/doh-proxy /usr/local/bin/doh-proxy

#------------------------------------------------------------------------------#
FROM alpine:latest

ENV DOH_RUN_DEPS libgcc runit shadow curl

RUN apk add --no-cache $DOH_RUN_DEPS

COPY --from=0 /usr/local/bin/doh-proxy /usr/local/bin/doh-proxy

RUN set -x && \
    groupadd _doh_proxy && \
    useradd -g _doh_proxy -s /dev/null -d /dev/null _doh_proxy && \
    mkdir -p /etc/service/doh-proxy

COPY entrypoint.sh /

EXPOSE 3000/udp 3000/tcp

RUN doh-proxy --version

HEALTHCHECK --start-period=5s --interval=60s \
CMD curl -H 'Content-Type: application/dns-udpwireformat' -f 'http://127.0.0.1:3000/dns-query?ct&dns=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB'>/dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
