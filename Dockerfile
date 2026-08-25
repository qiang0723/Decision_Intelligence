# 决策智能架构 · 研究站
# 纯静态站点，无构建步骤。镜像自带一份内容快照，便于整体搬走或分享；
# 日常编辑用 compose 的 bind mount 覆盖，改完刷新即可见（见 compose.yaml）。

FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="decision-intelligence-architecture-site" \
      org.opencontainers.image.description="企业 Agentic AI 与决策智能架构 · 方法论研究站（本地静态服务）"

RUN rm -f /etc/nginx/conf.d/default.conf
COPY docker/nginx.conf /etc/nginx/conf.d/site.conf

# 展示层 + 内容真身一并打包
COPY site/     /srv/site/
COPY content/  /srv/content/
COPY docs/     /srv/docs/
COPY README.md /srv/README.md

EXPOSE 80

# 注意：必须用 127.0.0.1 而不是 localhost。
# busybox 的 wget 会优先把 localhost 解析成 ::1，而 nginx 默认只监听 IPv4，
# 结果是健康检查恒为 unhealthy——服务其实是好的。
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1/healthz || exit 1
