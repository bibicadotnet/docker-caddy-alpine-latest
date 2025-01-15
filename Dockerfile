# Sử dụng Alpine mới nhất
FROM alpine:latest

RUN set -eux; \
    apk update && apk add --no-cache \
    curl \
    jq \
    wget \
    tar \
    bash \
    ca-certificates; \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
        x86_64)  binArch='amd64' ;; \
        armhf)   binArch='armv6' ;; \
        armv7)   binArch='armv7' ;; \
        aarch64) binArch='arm64' ;; \
        ppc64el|ppc64le) binArch='ppc64le' ;; \
        riscv64) binArch='riscv64' ;; \
        s390x)   binArch='s390x' ;; \
        *) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;; \
    esac; \
    latest_version=$(curl -s https://api.github.com/repos/caddyserver/caddy/releases/latest | jq -r .tag_name); \
    echo "Latest version is: $latest_version"; \
    wget -O /tmp/caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/$latest_version/caddy_$latest_version_linux_${binArch}.tar.gz"; \
    tar xzf /tmp/caddy.tar.gz -C /usr/bin caddy; \
    rm -f /tmp/caddy.tar.gz; \
    setcap cap_net_bind_service=+ep /usr/bin/caddy; \
    chmod +x /usr/bin/caddy; \
    caddy version
    
RUN set -eux; \
	mkdir -p \
		/config/caddy \
		/data/caddy \
		/etc/caddy \
		/usr/share/caddy \
	; \
	wget -O /etc/caddy/Caddyfile "https://github.com/caddyserver/dist/raw/33ae08ff08d168572df2956ed14fbc4949880d94/config/Caddyfile"; \
	wget -O /usr/share/caddy/index.html "https://github.com/caddyserver/dist/raw/33ae08ff08d168572df2956ed14fbc4949880d94/welcome/index.html"

# Thiết lập biến môi trường cho cấu hình và dữ liệu
ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data

LABEL org.opencontainers.image.version="latest"
LABEL org.opencontainers.image.title="Caddy"
LABEL org.opencontainers.image.description="A powerful, enterprise-ready, open-source web server with automatic HTTPS written in Go"
LABEL org.opencontainers.image.url="https://caddyserver.com"
LABEL org.opencontainers.image.documentation="https://caddyserver.com/docs"
LABEL org.opencontainers.image.vendor="Light Code Labs"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/caddyserver/caddy-docker"

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

WORKDIR /srv

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
