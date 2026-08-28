# ---------- 构建层：Maven 编译（依赖层缓存，改代码不重下依赖） ----------
# 钉在构建机原生架构：jar 与平台无关，多架构发布（amd64/arm64）时无需在 QEMU 里编译
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY deploy/maven-settings.xml /root/.m2/settings.xml
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q clean package -DskipTests

# ---------- 运行层：精简 JRE ----------
FROM eclipse-temurin:17-jre-jammy
LABEL app="shiguangji-server"

# 时区（与 MySQL/日志对齐东八区）+ curl（容器健康检查用）。
# apt 源换阿里云 https 镜像：官方源是明文 http，在本机代理（Fake-IP）环境下会被 502 拦截
ENV TZ=Asia/Shanghai
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && sed -i 's|http://ports.ubuntu.com/ubuntu-ports|https://mirrors.aliyun.com/ubuntu-ports|g; s|http://archive.ubuntu.com/ubuntu|https://mirrors.aliyun.com/ubuntu|g; s|http://security.ubuntu.com/ubuntu|https://mirrors.aliyun.com/ubuntu|g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# 非 root 运行
RUN groupadd -r app && useradd -r -g app app
WORKDIR /app
COPY --from=build /workspace/target/shiguangji-server.jar app.jar
RUN mkdir -p /app/uploads /app/logs && chown -R app:app /app
USER app

EXPOSE 8080
ENV JAVA_OPTS="-Xms256m -Xmx512m" \
    UPLOAD_DIR=/app/uploads \
    LOG_DIR=/app/logs

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# 健康检查：actuator 联通 DB/Redis 后才判定 UP
HEALTHCHECK --interval=15s --timeout=5s --retries=5 --start-period=90s \
  CMD curl -fsS http://localhost:8080/actuator/health || exit 1
