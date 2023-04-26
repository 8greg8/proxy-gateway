FROM alpine:latest

LABEL maintainer="Gregor Koporec <15978426+8greg8@users.noreply.github.com>"
LABEL version="2.0"
LABEL build_date="2023-04-26"

RUN apk update \
    && apk add --no-cache --virtual .build-deps build-base gcc make musl-dev \
    && apk add wget \
    && apk add krb5-dev krb5 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY cntlm-0.92.3 /cntlm-0.92.3

WORKDIR /cntlm-0.92.3

RUN chmod u+x configure \
    && ./configure --enable-kerberos \
    && make \
    && make install

# Delete packages in .build-deps
RUN apk del --no-cache .build-deps

EXPOSE 3128

ENTRYPOINT [ "/usr/sbin/cntlm", "-f", "-a", "gss", "-c", "/etc/cntlm.conf"]
