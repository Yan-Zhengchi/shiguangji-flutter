#!/bin/sh
# 每日备份：由 NAS 定时任务调用（群晖：控制面板→任务计划）
# 用法：在 deploy/ 目录设置好 .env 后执行本脚本
BACKUP_DIR="${DATA_DIR:-/volume1/docker/shiguangji}/backup"
mkdir -p "$BACKUP_DIR"
docker exec shiguangji-mysql mysqldump -u root -p"$MYSQL_PASSWORD" shiguangji \
  | gzip > "$BACKUP_DIR/shiguangji-$(date +%Y%m%d).sql.gz"
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +14 -delete    # 只保留 14 天
