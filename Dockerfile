# Sử dụng phiên bản mới nhất của Alpine
FROM alpine:latest

# Cài đặt các gói cần thiết
RUN apk add --no-cache \
    ca-certificates \
    libcap \
    mailcap \
    wget

# Tạo các thư mục cần thiết
RUN mkdir -p \
    /config/caddy \
    /data/caddy \
    /etc/caddy \
    /usr/share/caddy

# Tải Caddyfile và trang chào mừng mặc định
RUN wget -O /etc/caddy/Caddyfile "https://github.com/caddyserver/dist/raw/main/config/Caddyfile" && \
    wget -O /usr/share/caddy/index.html "https://github.com/caddyserver/dist/raw/main/welcome/index.html"

# Lấy phiên bản mới nhất của Caddy từ GitHub API
ENV CADDY_VERSION $(wget -qO- "https://api.github.com/repos/caddyserver/caddy/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

# Tải và cài đặt Caddy
RUN set -eux; \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
        x86_64)  binArch='amd64' ;; \
        armhf)   binArch='armv6' ;; \
        armv7)   binArch='armv7' ;; \
        aarch64) binArch='arm64' ;; \
        ppc64el|ppc64le) binArch='ppc64le' ;; \
        riscv64) binArch='riscv64' ;; \
        s390x)   binArch='s390x' ;; \
        *) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
    esac; \
    wget -O /tmp/caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/$CADDY_VERSION/caddy_${CADDY_VERSION#v}_linux_${binArch}.tar.gz"; \
    tar x -z -f /tmp/caddy.tar.gz -C /usr/bin caddy; \
    rm -f /tmp/caddy.tar.gz; \
    setcap cap_net_bind_service=+ep /usr/bin/caddy; \
    chmod +x /usr/bin/caddy; \
    caddy version

# Thiết lập các biến môi trường
ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data

# Thiết lập các nhãn (labels)
LABEL org.opencontainers.image.version=$CADDY_VERSION
LABEL org.opencontainers.image.title=Caddy
LABEL org.opencontainers.image.description="a powerful, enterprise-ready, open source web server with automatic HTTPS written in Go"
LABEL org.opencontainers.image.url=https://caddyserver.com
LABEL org.opencontainers.image.documentation=https://caddyserver.com/docs
LABEL org.opencontainers.image.vendor="Light Code Labs"
LABEL org.opencontainers.image.licenses=Apache-2.0
LABEL org.opencontainers.image.source="https://github.com/caddyserver/caddy-docker"

# Mở các cổng mạng
EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

# Thiết lập thư mục làm việc
WORKDIR /srv

# Chạy Caddy
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
