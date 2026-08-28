# 食光记 NAS 部署指南

## 前置条件

- NAS 上已安装 Docker 和 Docker Compose（群晖/威联通自带，或手动安装）
- 已将镜像推送到 Docker Hub（你已经完成了）

## 部署步骤

### 1. 上传部署文件到 NAS

将以下文件/目录上传到 NAS（例如 `/volume1/docker/shiguangji/`）：

```
shiguangji/
├── docker-compose.yml
├── .env
└── mysql/
    └── init.sql
```

**方法一：scp 上传**
```bash
scp -r deploy/ user@nas-ip:/volume1/docker/shiguangji/
```

**方法二：群晖 File Station**
- 打开 File Station → 创建共享文件夹 `docker/shiguangji`
- 上传 `docker-compose.yml`、`.env`、`mysql/init.sql`

### 2. 修改 .env 配置

在 NAS 上编辑 `.env` 文件：

```bash
cd /volume1/docker/shiguangji
nano .env   # 或 vi .env
```

**必须修改的项：**

```bash
# 改为你的 Docker Hub 镜像地址
DOCKER_IMAGE=你的用户名/shiguangji-server:1.0.0

# NAS 上的数据存储目录（绝对路径）
# 群晖: /volume1/docker/shiguangji
# 威联通: /share/CACHEDEV1_DATA/docker/shiguangji
DATA_DIR=/volume1/docker/shiguangji

# 建议修改默认密码（首次部署时）
MYSQL_PASSWORD=你的MySQL密码
REDIS_PASSWORD=你的Redis密码
JWT_SECRET=你的JWT密钥
```

### 3. 创建数据目录

```bash
mkdir -p /volume1/docker/shiguangji/{mysql/data,redis/data,uploads,logs}
```

### 4. 启动服务

```bash
cd /volume1/docker/shiguangji
docker compose up -d
```

首次启动会自动：
- 拉取 Docker Hub 镜像
- 初始化 MySQL 数据库和表
- 启动 Redis
- 等待依赖就绪后启动应用

### 5. 验证运行

```bash
# 查看容器状态
docker compose ps

# 查看应用日志
docker compose logs -f app

# 健康检查
curl http://localhost:8080/actuator/health
```

浏览器访问：`http://NAS内网IP:8080`

---

## 数据目录结构

启动后 `DATA_DIR` 下的目录结构：

```
/volume1/docker/shiguangji/
├── mysql/data/          # MySQL 数据文件（自动创建）
├── redis/data/          # Redis 持久化（AOF）
├── uploads/             # 用户上传的图片等文件
└── logs/                # 应用日志
```

## 常见问题

### 上传图片报「文件保存失败」(code 50000)

应用容器以**非 root 用户（UID/GID 999）**运行，宿主机的 `data/uploads`、`data/logs`
目录必须归它所有，否则写文件直接 Permission denied。修复：

```bash
cd /volume1/docker/shiguangji
chown -R 999:999 data/uploads data/logs
# 验证：容器内能写探针文件即 OK
docker compose exec app sh -c 'touch /app/uploads/.probe && echo WRITE_OK && rm /app/uploads/.probe'
```

若仍失败，检查磁盘是否写满：`df -h /volume1`

## 数据库变更（Flyway）

建表和改表由后端 **Flyway** 自动管理，源码在 `src/main/resources/db/migration/`：

- **应用每次启动时**自动执行未应用的版本脚本（先迁移、后对外服务），NAS 上 `docker compose pull && docker compose up -d` 即完成表结构升级，无需手工 ALTER
- 已执行记录存在 MySQL 的 `flyway_schema_history` 表里
- **开发者改表姿势**：新增 `V<下一个版本号>__描述.sql`（如 `V2__add_recipe_tag.sql`），只增不改历史文件；SQL 用"先加后删"（本版加字段，下版再删），保证与任意旧版本兼容
- 已有部署升级：首次启动自动打基线（当前结构视为 V1，跳过 V1）；全新部署：空库从 V1 全量建表 + 种子数据
- **升级前先备份**：`sh backup.sh`（迁移是单向的，出问题靠备份 + 回退上一版镜像）

## 常用命令

```bash
# 停止服务（保留数据）
docker compose down

# 停止并删除数据（慎用！）
docker compose down -v

# 重启应用（不重建数据库）
docker compose restart app

# 更新镜像后重新部署
docker compose pull
docker compose up -d

# 查看某个服务的日志
docker compose logs -f mysql
docker compose logs -f redis
```

## 备份

MySQL 数据备份（定期执行）：
```bash
docker exec shiguangji-mysql \
  mysqldump -u shiguangji -p'你的密码' shiguangji \
  > /volume1/docker/shiguangji/backup_$(date +%Y%m%d).sql
```

---

## 注意事项

1. **镜像地址**：`.env` 中的 `DOCKER_IMAGE` 必须与你推送到 Docker Hub 的地址一致
2. **端口冲突**：如果 NAS 的 8080 端口被占用，修改 `.env` 中的 `APP_PORT`
3. **数据库名**：Docker 部署使用 `shiguangji` 数据库（init.sql 自动创建）
4. **首次启动较慢**：MySQL 初始化 + 应用启动约需 1-2 分钟，请耐心等待
