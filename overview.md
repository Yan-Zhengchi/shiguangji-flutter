# 食光记后端 · 交付总览

> 版本：v1.0 ｜ 日期：2026-08-26 ｜ 配套：《食光记-开发文档.md》《食光记-架构设计文档.md》
> 状态：**已实现、已构建、已测试、Docker 跑通** ✅

---

## 一、交付内容

按开发文档与架构设计文档 1:1 实现，并完成 Docker 容器化与端到端验证。

### 1. 后端源码（Spring Boot 3.3 · Java 17 · Maven）

```
pom.xml + src/main/
├── java/com/shiguangji/  (73 个 Java 文件)
│   ├── ShiguangjiApplication.java     # 入口（@EnableScheduling + @MapperScan）
│   ├── common/      Result / ErrorCode / BizException / GlobalExceptionHandler
│   ├── config/      SecurityConfig / JacksonConfig / WebConfig
│   ├── security/    JwtUtil / JwtAuthenticationFilter / SgjSecurityUtils
│   ├── util/        RedisCache（SCAN 删）/ RedisKeys
│   ├── entity/      13 张表实体（雪花ID + 逻辑删除）
│   ├── mapper/      13 个 Mapper（RecipeMapper/FavoriteMapper 含自定义 XML）
│   ├── dto/         请求/响应 DTO（含 Long→String 序列化）
│   ├── service/     Auth/Category/Recipe/Search/Favorite/User/Family/Upload/Counter
│   └── controller/  8 个 REST 控制器
└── resources/
    ├── application.yml        # 环境变量注入（MYSQL/REDIS/JWT/UPLOAD）
    └── mapper/*.xml           # 瀑布流/搜索/收藏列表/计数回写 SQL
```

### 2. Docker 部署物（`deploy/`）

| 文件 | 作用 |
|---|---|
| `Dockerfile` | 多阶段构建（Maven 编译 → JRE 运行，≈300MB） |
| `docker-compose.yml` | app + mysql + redis 一键编排（healthcheck + 依赖启动） |
| `maven-settings.xml` | 阿里云 Maven 镜像加速 |
| `mysql/init.sql` | 全量 DDL + 种子数据（含 `SET NAMES utf8mb4`） |
| `.env` / `.env.example` | 环境变量（DATA_DIR 持久化根目录 + 随机密码） |
| `backup.sh` | 每日 mysqldump 备份脚本 |
| `smoke_test.py` | 端到端 API 冒烟测试（54 断言 + 5 持久化断言） |

### 3. 全部 API（/api/v1）

认证（register/login/refresh/logout/me）· 分类 · 首页瀑布流 · 热门榜 · 搜索（FULLTEXT+历史+热搜）· 菜谱 CRUD · 图片上传 · 收藏 · 个人统计 · 家庭菜谱共享 —— **共 27 个接口**，全部冒烟通过。

---

## 二、如何运行

### 一键启动（本地 / NAS 通用）

```bash
cd deploy
cp .env.example .env && vi .env     # 改 DATA_DIR（NAS 用 /volume1/docker/shiguangji）
docker compose up -d                # ★ 一键启动三容器
docker compose ps                   # 三容器应均 healthy
curl http://localhost:8080/actuator/health   # {"status":"UP"}
```

### 跑测试

```bash
python deploy/smoke_test.py                  # 54 条 API 断言
python deploy/smoke_test.py --verify-persist # 重启后数据持久化断言
```

### 日常运维

```bash
docker compose logs -f app                  # 看日志
docker compose down && docker compose up -d  # 重启（数据不丢）
```

---

## 三、测试结果

| 项 | 结果 |
|---|---|
| 镜像构建 | ✅ 通过（73 Java 文件编译成功，6.9s） |
| 三容器启动 | ✅ app/mysql/redis 均 healthy |
| API 冒烟测试 | ✅ **54/54 PASS**（覆盖认证/上传/菜谱/搜索/收藏/个人/家庭/Token 全链路） |
| 数据持久化验证 | ✅ **5/5 PASS**（compose down/up 后用户/菜谱/修改/种子数据全在） |
| 宿主机数据落盘 | ✅ data/mysql(204MB) + data/redis + data/uploads |

---

## 四、关键技术决策（与文档的偏差/增强）

1. **Long → String 序列化**：雪花 ID 超出 JS 安全整数，全局 Jackson 配置将 Long 序列化为字符串（任何客户端都安全）。
2. **实时计数**：详情页浏览/收藏数 = DB 基数 + Redis 待回写增量，用户即时看到最新值（不依赖每小时回写）。
3. **Redis 健康检查**：compose 给 redis 服务补了 `REDIS_PASSWORD` 环境变量，供 healthcheck 的 `$REDIS_PASSWORD` 取用。
4. **init.sql 字符集**：顶部加 `SET NAMES utf8mb4`，确保中文种子数据按 UTF-8 读入。
5. **图片存储**：OSS 未配置时默认落盘到 `UPLOAD_DIR`（容器 `/app/uploads` → 宿主机 `DATA_DIR/uploads`），静态映射 `/uploads/**`。
6. **Maven 镜像加速**：`maven-settings.xml` 配阿里云仓库，国内构建快。
7. **Service 未抽接口**：为降低交付与维护成本，Service 用具体类（非接口+Impl），符合文档"预留拆分"的轻量做法。

---

## 五、NAS 部署（用户最终目标）

1. NAS 上 `mkdir -p /volume1/docker/shiguangji`，把 `deploy/` 上传进去
2. `.env` 改 `DATA_DIR=/volume1/docker/shiguangji`、生成随机密码（`openssl rand -hex 16`）、JWT（`openssl rand -base64 48`）
3. `docker compose up -d` —— 容器随删随建，**数据全在 NAS 目录，不丢**
4. （可选）NAS 任务计划每日跑 `backup.sh` 做数据库备份

---

## 六、目录结构

```
D:\workbuddy\2026-08-26-19-16-43\
├── pom.xml + src/                 # 后端工程
├── 食光记-深色玻璃版.html         # 设计稿原型
├── 食光记-架构设计文档.md
├── 食光记-开发文档.md
├── overview.md                    # 本文档
└── deploy/                        # Docker 编排物（见上）
    └── data/                      # 持久化数据（mysql/redis/uploads/logs）
```
