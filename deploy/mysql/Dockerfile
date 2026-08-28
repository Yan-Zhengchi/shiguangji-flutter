FROM mysql:8.0
# 建表/改表统一由后端 Flyway 迁移管理（src/main/resources/db/migration），
# 首次启动 MySQL 容器只负责创建空库（compose 里 MYSQL_DATABASE）。
