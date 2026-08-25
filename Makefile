# 决策智能架构 · 研究站 —— 本地服务
PORT ?= 8081

.PHONY: up down restart logs status build open check

up:            ## 启动（后台常驻）
	SITE_PORT=$(PORT) docker compose up -d --build
	@echo "→ http://localhost:$(PORT)"

down:          ## 停止并移除容器
	docker compose down

restart:       ## 重启
	docker compose restart

logs:          ## 查看日志（Ctrl-C 退出）
	docker compose logs -f

status:        ## 查看状态
	docker compose ps

build:         ## 只构建镜像（内容打包进镜像，可整体搬走）
	docker compose build

open:          ## 用默认浏览器打开
	open http://localhost:$(PORT)

check:         ## 校验所有页面可访问 + 内部链接无断链
	@bash scripts/check.sh $(PORT)
