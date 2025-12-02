# CNTLM

CNTLM service was migrated from systemd service to docker container 

## Start the service

```bash
cd ~/cntlm
docker-compose up -d
```

## Configurations
Change configurations by adding the value of <PROXY_IP> and <PROXY_PORT>.

Current variable values:
<PROXY_IP>=<docker-bridge-address>
<PROXY_PORT>=3128

### Environment variable

```bash
sudo vim /etc/zsh/zshenv
```
```text
export http_proxy=http://<PROXY_IP>:<PROXY_PORT>
export https_proxy=http://<PROXY_IP>:<PROXY_PORT>
```

### APT
```bash
sudo vim /etc/apt/apt.conf.d/proxy.conf
```
```text
Acquire::http::Proxy “http://<PROXY_IP>:<PROXY_PORT>/”;
Acquire::https::Proxy “https://<PROXY_IP>:<PROXY_PORT>/”;
```

### SNAP

```bash
sudo systemctl edit snapd.service
```
```text
[Service]
Environment=http_proxy=http://<PROXY_IP>:<PROXY_PORT>
Environment=https_proxy=http://$<PROXY_IP>:<PROXY_PORT>
```

### Git
```bash
vim ~/.gitconfig
```
```text
[http]
sslVerify = false
proxy = http://$<PROXY_IP>:<PROXY_PORT>
```

### Docker
...
