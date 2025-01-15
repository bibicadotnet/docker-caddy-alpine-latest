# Sử dụng phiên bản mới nhất của Alpine
FROM alpine:latest

# Bắt đầu với set -eux để bắt lỗi và in thông tin chi tiết
RUN set -eux; \
    echo "Cài đặt các gói cần thiết..." && \
    apk add --no-cache \
        ca-certificates \
        libcap \
        mailcap \
        wget || { echo "Lỗi: Không thể cài đặt các gói cần thiết"; exit 1; }

# Tạo các thư mục cần thiết
RUN set -eux; \
    echo "Tạo các thư mục cần thiết..." && \
    mkdir -p \
        /config/caddy \
        /data/caddy \
        /etc/caddy \
        /usr/share/caddy || { echo "Lỗi: Không thể tạo thư mục"; exit 1; }

# Tải Caddyfile và trang chào mừng mặc định từ commit cụ thể trên GitHub
RUN set -eux; \
    echo "Tải Caddyfile và trang chào mừng mặc định..." && \
    wget -O /etc/caddy/Caddyfile "https://github.com/caddyserver/dist/raw/33ae08ff08d168572df2956ed14fbc4949880d94/config/Caddyfile" || { echo "Lỗi: Không thể tải Caddyfile"; exit 1; } && \
    wget -O /usr/share/caddy/index.html "https://github.com/caddyserver/dist/raw/33ae08ff08d168572df2956ed14fbc4949880d94/welcome/index.html" || { echo "Lỗi: Không thể tải trang chào mừng"; exit 1; }

# Lấy phiên bản mới nhất của Caddy từ GitHub API
RUN set -eux; \
    echo "Lấy phiên bản mới nhất của Caddy từ GitHub API..." && \
    CADDY_VERSION=$(wget -qO- "https://api.github.com/repos/caddyserver/caddy/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    echo "CADDY_VERSION: $CADDY_VERSION" || { echo "Lỗi: Không thể lấy phiên bản Caddy từ GitHub API"; exit 1; }

# In ra kiến trúc hệ thống để kiểm tra
RUN set -eux; \
    echo "Kiến trúc hệ thống: $(apk --print-arch)" || { echo "Lỗi: Không thể xác định kiến trúc hệ thống"; exit 1; }

# Tải và cài đặt Caddy
RUN set -eux; \
    echo "Tải và cài đặt Caddy..." && \
    apkArch="$(apk --print-arch)" && \
    case "$apkArch" in \
        x86_64)  binArch='amd64' ;; \
        armhf)   binArch='armv6' ;; \
        armv7)   binArch='armv7' ;; \
        aarch64) binArch='arm64' ;; \
        ppc64el|ppc64le) binArch='ppc64le' ;; \
        riscv64) binArch='riscv64' ;; \
        s390x)   binArch='s390x' ;; \
        *) echo >&2 "Lỗi: Kiến trúc không được hỗ trợ ($apkArch)"; exit 1 ;;\
    esac && \
    wget --no-check-certificate -O /tmp/caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/$CADDY_VERSION/caddy_${CADDY_VERSION#v}_linux_${binArch}.tar.gz" || { echo "Lỗi: Không thể tải Caddy từ GitHub"; exit 1; } && \
    tar x -z -f /tmp/caddy.tar.gz -C /usr/bin caddy || { echo "Lỗi: Không thể giải nén Caddy"; exit 1; } && \
    rm -f /tmp/caddy.tar.gz && \
    setcap cap_net_bind_service=+ep /usr/bin/caddy || { echo "Lỗi: Không thể thiết lập cap_net_bind_service"; exit 1; } && \
    chmod +x /usr/bin/caddy || { echo "Lỗi: Không thể thiết lập quyền thực thi cho Caddy"; exit 1; } && \
    caddy version || { echo "Lỗi: Không thể kiểm tra phiên bản Caddy"; exit 1; }

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
