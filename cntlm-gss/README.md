# cntlm-gss-docker

A container to function as a proxy, based on [CNTLM](http://cntlm.sourceforge.net). Other systemc can connect to this proxy for their web access. This container authenticates to an external proxy and can be used by others without authentication details.

```text
              +- - - - - - -+  +- - - - - - - - -+
              | no password |  | password (hash) |
              +- - - - - - -+  +- - - - - - - - -+
                      |              |
+------------------+  V   +-------+  V   +-----------------+      +----------+
| your workstation | ---> | cntlm | ---> | corporate proxy | ---> | internet |
+------------------+      +-------+      +-----------------+      +----------+
```

- cntlm with kerberos patch in a docker container

- [cntlm v0.92.3 source code](https://sourceforge.net/projects/cntlm/files/cntlm/cntlm%200.92.3/) and [kerberos patch](https://sourceforge.net/p/cntlm/feature-requests/_discuss/thread/4a3be422/22d0/attachment/201211-cntlm-kerberos-authentication.patch) were both obtained from [sourceforge](https://sourceforge.net/projects/cntlm).

- some modification was made to `Makefile` to allow patch to be applied [see commit ae4cb8d6](https://github.com/maksteel/cntlm-gss-docker/commit/ab986db365f0c5809891c64dd035244ced6372a2)

- patch was applied using below command after the Makefile was modified.

    ```
    git apply -p0 --ignore-whitespace --directory=cntlm-0.92.3 \
    201211-cntlm-kerberos-authentication.patch 
    ```

## Build the container

```
docker build --progress=plain -t cntlm-gss . &> build.log
```

## Run the container

```
docker run -it -v ${PWD}/cntlm.conf:/etc/cntlm.conf -p 53128:3128 cntlm-gss-docker:0.92.3  -a ntlmv2
```

> Note: specify `-a ntlmv2` if you want to use NTLMv2 as a fallback procedure when Kerberos fails

Once the container is running, use `http://localhost:53128` as your proxy on your host.

## Using in Docker Compose

You can use this container quite well in a docker-compose. Docker compose can simply be used to run as a stand-alone proxy. In that case the docker-compose.yml simply saves all variable, and can be started by running:

```console
docker-compose up
```

## Sample contents of `${PWD}/cntlm.conf`

```
Username    username
Domain      DOMAIN.EXAMPLE.ORG
Password
Proxy       parent.proxy.example.org:8080
NoProxy     localhost, 127.0.0.*, 10.*, 192.168.*
Listen      3128
Auth            NTLMv2
PassNTLMv2      hashed-ntlm-passwrd
```
