#
# Dockerfile for shadowsocks-libev and simple-obfs
#

FROM chenhw2/alpine:base
MAINTAINER CHENHW2 <https://github.com/chenhw2>

ARG SS_VER=69c41d9752fe37580ba1d6b9b3023aff28655f07
ARG SS_URL=https://github.com/shadowsocks/shadowsocks-libev/archive/$SS_VER.tar.gz
ARG OBFS_VER=2955a57624add482588b41fad68bbcd4c632fff5
ARG OBFS_URL=https://github.com/shadowsocks/simple-obfs/archive/$OBFS_VER.tar.gz

RUN set -ex && \
    apk add --update --no-cache --virtual \
                                .build-deps \
                                autoconf \
                                automake \
                                build-base \
                                curl \
                                libev-dev \
                                libtool \
                                linux-headers \
                                libsodium-dev \
                                mbedtls-dev \
                                openssl-dev \
                                pcre-dev \
                                tar \
                                c-ares-dev && \

    cd /tmp && \
    curl -sSL $SS_URL | tar xz --strip 1 && \
    cd /tmp/libcork  && curl -sSL https://github.com/shadowsocks/libcork/archive/3bcb8324431d3bd4be5e4ff2a4323b455c8d5409.tar.gz  | tar xz --strip 1 && \
    cd /tmp/libbloom && curl -sSL https://github.com/shadowsocks/libbloom/archive/7a9deb893fc1646c0b9186b50d46358379953d4b.tar.gz | tar xz --strip 1 && \
    cd /tmp/libipset && curl -sSL https://github.com/shadowsocks/ipset/archive/3ea7fe30adf4b39b27d932e5a70a2ddce4adb508.tar.gz    | tar xz --strip 1 && \
    cd /tmp && \
    ./autogen.sh && \
    ./configure --prefix=/usr --disable-documentation && \
    make install && \
    cd .. && \

    runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $runDeps && \

    cd /tmp && \
    curl -sSL $OBFS_URL | tar xz --strip 1 && \
    ./autogen.sh && \
    ./configure --prefix=/usr --disable-documentation && \
    make install && \
    cd .. && \

    runDeps="$( \
        scanelf --needed --nobanner /usr/bin/obfs-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $runDeps && \

    apk del --purge \
                    .build-deps \
                    autoconf \
                    automake \
                    build-base \
                    curl \
                    libev-dev \
                    libtool \
                    linux-headers \
                    libsodium-dev \
                    mbedtls-dev \
                    openssl-dev \
                    pcre-dev \
                    tar \
                    c-ares-dev && \
    rm -rf /tmp/* /var/cache/apk/*

USER nobody

ENV SERVER_PORT=8388 \
    METHOD=chacha20-ietf-poly1305 \
    TIMEOUT=120
ENV PASSWORD=''
ENV ARGS=''

EXPOSE $SERVER_PORT/tcp $SERVER_PORT/udp

CMD ss-server \
 -s 0.0.0.0 \
 -p $SERVER_PORT \
 -k ${PASSWORD:-$(hostname)} \
 -m $METHOD \
 -t $TIMEOUT \
 --fast-open -u \
 ${ARGS:--d 8.8.8.8}
