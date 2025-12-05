# Copyright (c) 2025 Gregor Koporec <15978426+8greg8@users.noreply.github.com>

# -------------------------------
# Global Build Arguments
# override with --build-arg ARGUMENT="..."
# -------------------------------
ARG BUILD_ARCH="amd64"
# FROM alpine:latest returns X509: Certificate Signed by Unknown Authority
ARG VERSION=3.17 

FROM --platform=$TARGETPLATFORM alpine:$VERSION

# -------------------------------
# Stage-Specific Build Arguments
# -------------------------------
ARG VERSION
ARG BUILD_DATE
ARG BUILD_VERSION
ARG TRUSTED_INTERNAL_HOST
# This is not working due to SSL errors
#RUN apk update \
#RUN apk add --allow-untrusted  --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/main --no-cache --virtual .build-deps build-base gcc make musl-dev \
#&& apk add --allow-untrusted  --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/main wget \
#&& apk add --allow-untrusted  --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/main krb5-dev krb5 \
ARG REPO=http://dl-cdn.alpinelinux.org/alpine/v$VERSION/main
ARG PROJECT=/cntlm
ARG EXT_DATA=/data

# -------------------------------
# Metadata
# -------------------------------
LABEL maintainer="Gregor Koporec <15978426+8greg8@users.noreply.github.com>" version=$BUILD_VERSION build_date=$BUILD_DATE


# -------------------------------
# Certificates
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
    sed -i 's/https/http/g' /etc/apk/repositories; \
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
    make; \
    make install; \
    make clean; \
    apk del --no-cache .build-deps; \
# Add runtime dependencies
    apk add --no-cache krb5; \
# Create data dir
    mkdir $EXT_DATA \
# Clean cache
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add config files
# Config files will be added via volume
#COPY krb5.conf cntlm.conf /etc/
# -------------------------------
# External Dependencies and Configs
# -------------------------------
VOLUME $EXT_DATA

# Add cron job to renew ticket every 5 hours
COPY renew_ticket.sh /renew_ticket.sh
RUN echo "* */5 * * * /renew_ticket.sh" >> /var/spool/cron/crontabs/root

#ENTRYPOINT [ "/usr/sbin/cntlm", "-f", "-a", "gss", "-c", "/etc/cntlm.conf"]
# Add run script
COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3128