# 食光记（shiguangji）

家常菜谱全栈项目：Spring Boot 3.3 + MyBatis-Plus 后端（`src/main/java/com/shiguangji`）、Flutter 前端（`shiguangji_app/lib`）、docker-compose 部署到 NAS（`deploy/`）。数据库 MySQL 8（本地容器 `sgj-mysql`，NAS 数据卷持久化），Redis 缓存，图片本地落盘 `uploads/`。

## ⚠️ 数据库变更规范（任何改动必须遵守）

表结构由 **Flyway** 自动迁移管理，迁移脚本在 `src/main/resources/db/migration/`。应用启动时自动执行未应用的版本（先迁移、后对外服务），部署端 `docker compose pull && up -d` 即完成升级。**任何人（包括 Claude）不得绕过这套机制。**

### 铁律

1. **一切表结构变更**（建表、加/改/删字段、索引、种子数据）必须新建迁移文件：`V<递增版本号>__简短英文描述.sql`，如 `V2__add_recipe_tag.sql`、`V3__backfill_family_role.sql`
2. **禁止修改或删除已存在的迁移文件**——Flyway 按 checksum 校验历史文件，改动会导致启动失败；发现历史迁移有错，新建一个修正版本（`V<N+1>`）
3. **禁止**在 Java 代码里执行 DDL、禁止用 JPA/MyBatis 自动建表、禁止要求用户 ssh 上 NAS 手工执行 SQL
4. **先加后删**：本版只加字段（NULL 或带默认值，保证对旧数据与旧版本代码兼容）；代码已停止使用的字段/表，等下一个版本再用迁移删除。重命名 = 加新列 + 迁移里回填 + 下版删旧列
5. **一个提交内自洽**：改表的同一提交里同步更新对应实体类（`entity/*.java`，下划线列名自动映射驼峰）和受影响的 mapper/SQL，否则启动即错
6. **版本号冲突**：如果 rebase 后发现别人（或另一分支）已占用你的版本号，只改自己文件的版本号为下一个可用号，绝不改对方文件
7. **验证义务**：涉及 DB 变更的改动，落地前必须本地重启后端验证（看日志中 Flyway 行、查 `flyway_schema_history` 的 success）；全新建表类迁移还应在空库上验证一遍（可起一次性 `mysql:8.0` 容器导入执行）
8. **发布纪律**：迁移是单向的（社区版 Flyway 无 down），提醒用户升级前跑 `deploy/backup.sh`；生产镜像建议同时打版本 tag（如 `:1.2.0`），出问题才能回退

### 当前状态

- `V1__init.sql` = 全量建表（13 张表）+ 分类/厨具种子数据，来自原 `deploy/mysql/init.sql`（已删除）
- 已有部署的库通过 baseline（`baseline-on-migrate: true`，`baseline-version: 1`）跳过 V1；全新安装从 V1 全量执行
- 下一个可用版本号从 **V2** 开始

## 其他约定

- 前端网络层统一走 `ApiClient.dio`（自签证书兼容、登录态失效自动踢回登录页），不要另起裸 `Dio`
- 新增数据展示面（卡片计数等）记得在变更动作处 `ref.invalidate` 对应 provider（Riverpod 缓存不自动失效）
- 上传图片：前端 `ImageCompressor` 压到 ≤500KB（web/gif 跳过），后端 `UploadService` 兜底压缩；前端压缩失败提示后传原图，不阻断
