# Copyright (c) 2025 Gregor Koporec <15978426+8greg8@users.noreply.github.com>
# SPDX-License-Identifier: GPL-2.0-or-later
# Modified by Gregor Koporec, 2023-2026: see MODIFICATIONS.md. Derived from github.com/maksteel/cntlm-gss-docker (GPL-2.0).

# -------------------------------
# Global Build Arguments
# override with --build-arg ARGUMENT="..."
# -------------------------------
ARG BUILD_ARCH="amd64"
# FROM alpine:latest returns X509: Certificate Signed by Unknown Authority
ARG VERSION=3.17 

FROM alpine:$VERSION

# -------------------------------
# Stage-Specific Build Arguments
# -------------------------------
ARG VERSION
ARG BUILD_DATE
ARG BUILD_VERSION
ARG TRUSTED_INTERNAL_HOST
# Set to 1 to downgrade the Alpine package repositories to http (only for networks that break TLS)
ARG APK_USE_HTTP=0
# This is not working due to SSL errors
#RUN apk update \
#RUN apk add --allow-untrusted  --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/main --no-cache --virtual .build-deps build-base gcc make musl-dev \
#&& apk add --allow-untrusted  --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/main wget \
#&& apk add --allow-untrusted  --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/main krb5-dev krb5 \
ARG REPO=http://dl-cdn.alpinelinux.org/alpine/v$VERSION/main

# Directories
ARG PROJECT=/cntlm
ARG EXT_DATA=/data

# -------------------------------
# Metadata
# -------------------------------
LABEL maintainer="Gregor Koporec <15978426+8greg8@users.noreply.github.com>" version=$BUILD_VERSION build_date=$BUILD_DATE


# -------------------------------
# Certificates and source
# -------------------------------
# Add custom root CA for internal package sources or APIs
COPY certs/ /usr/local/share/ca-certificates/
COPY cntlm-0.92.3 $PROJECT

# -------------------------------
# Working Directory
# -------------------------------
WORKDIR $PROJECT

# -------------------------------
# System Dependencies
# -------------------------------
# Install tools required for the project
# Build cntlm with kerberos enabled
RUN set -eux; \
    if [ "$APK_USE_HTTP" = "1" ]; then sed -i 's/https/http/g' /etc/apk/repositories; fi; \
    apk update; \
# update certificates
    apk add --no-cache --virtual .cert ca-certificates; \
    update-ca-certificates; \
    apk del --no-cache .cert; \
# build dependencies for cnltm
    apk add --no-cache --virtual .build-deps \
        build-base \
        gcc \
        make \
        musl-dev \
        krb5-dev; \
    chmod u+x configure; \
    ./configure --enable-kerberos; \
    make -j"$(getconf _NPROCESSORS_ONLN)"; \
    make install; \
    make clean; \
    apk del --no-cache .build-deps; \
# Add runtime dependencies
    apk add --no-cache krb5; \
# Create config + data dir
    mkdir -p ${EXT_DATA}/conf ${EXT_DATA}/secrets; \
# Clean cache
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# -------------------------------
# Dependencies and Configs
# -------------------------------
# ----- Default configs (work out-of-the-box)
COPY conf/ /etc/

# Explicit environment variables

# ----- Env knobs (users can point to alt locations under /data/conf)
ENV CNTLM_CONFIG=/etc/cntlm.conf \
    KRB5_CONFIG=/etc/krb5.conf \
    KRB5CCNAME=/tmp/krb5cc_1000 \
    AD_USER=aduser

# Bind to this volume if custom config is needed
VOLUME ${EXT_DATA}

# -------------------------------
# Scripts
# -------------------------------
COPY scripts/ /
RUN chmod +x /docker-entrypoint.sh /renew_ticket.sh

# Add cron job to renew ticket every 5 hours
RUN echo "* */5 * * * /renew_ticket.sh" >> /var/spool/cron/crontabs/root

EXPOSE 3128
ENTRYPOINT ["/docker-entrypoint.sh"]