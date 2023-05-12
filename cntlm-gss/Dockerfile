# FROM alpine:latest returns X509: Certificate Signed by Unknown Authority
ARG VERSION=3.17
FROM alpine:$VERSION


LABEL maintainer="Gregor Koporec <15978426+8greg8@users.noreply.github.com>"
LABEL version="2.1"
LABEL build_date="2023-05-12"

# This is not working due to SSL errors
#RUN apk update \
#RUN apk add --allow-untrusted  --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/main --no-cache --virtual .build-deps build-base gcc make musl-dev \
#&& apk add --allow-untrusted  --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/main wget \
#&& apk add --allow-untrusted  --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/main krb5-dev krb5 \

ARG VERSION
ARG REPO=http://dl-cdn.alpinelinux.org/alpine/v$VERSION/main

RUN apk add --allow-untrusted --repository $REPO --no-cache --virtual .build-deps build-base gcc make musl-dev \
    && apk add --allow-untrusted --repository $REPO wget \
    && apk add --allow-untrusted --repository $REPO krb5-dev krb5 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Build cntlm with kerberos enabled
COPY cntlm-0.92.3 /cntlm-0.92.3
WORKDIR /cntlm-0.92.3
RUN chmod u+x configure \
    && ./configure --enable-kerberos \
    && make \
    && make install

# Delete packages in .build-deps
RUN apk del --no-cache .build-deps

# Add config files
COPY krb5.conf /etc/krb5.conf
COPY cntlm.conf /etc/cntlm.conf

# Add cron job to renew ticket every 5 hours
COPY renew_ticket.sh /renew_ticket.sh
RUN chmod +x /renew_ticket.sh \
    && echo "* */5 * * * /renew_ticket.sh" >> /var/spool/cron/crontabs/root

# Add run script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3128

#ENTRYPOINT [ "/usr/sbin/cntlm", "-f", "-a", "gss", "-c", "/etc/cntlm.conf"]
ENTRYPOINT ["/entrypoint.sh"]
