-- 食光记 MySQL 全量 DDL（首次启动自动执行）
-- 指定客户端字符集，确保 .sql 文件中的中文按 UTF-8 读入（避免种子数据乱码）
SET NAMES utf8mb4;
CREATE DATABASE IF NOT EXISTS shiguangji DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE shiguangji;

CREATE TABLE `user` (
  id            BIGINT PRIMARY KEY,
  username      VARCHAR(32)  NOT NULL UNIQUE,
  password_hash VARCHAR(100) NOT NULL,
  nickname      VARCHAR(32)  NOT NULL,
  phone         VARCHAR(20)  NULL,
  avatar_url    VARCHAR(255) NULL,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted       TINYINT DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE `category` (
  id   BIGINT PRIMARY KEY,
  name VARCHAR(16) NOT NULL,          -- 凉菜/热菜/鱼虾/肉类/蔬菜
  icon VARCHAR(64),
  sort INT DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE `tool` (
  id   BIGINT PRIMARY KEY,
  name VARCHAR(16) NOT NULL           -- 炒锅/蒸锅/烤箱/微波炉/砂锅/空气炸锅
) ENGINE=InnoDB;

CREATE TABLE `recipe` (
  id              BIGINT PRIMARY KEY,
  user_id         BIGINT NOT NULL,
  category_id     BIGINT NOT NULL,
  title           VARCHAR(64) NOT NULL,
  description     VARCHAR(1000),
  cover_url       VARCHAR(255),
  servings        INT DEFAULT 2,          -- 人份
  cook_minutes    INT DEFAULT 30,
  difficulty      TINYINT DEFAULT 2,      -- 1简单 2中等 3困难
  tips            VARCHAR(1000),          -- 妙招
  notes           VARCHAR(1000),          -- 注意事项（\n 分隔）
  exp_text        VARCHAR(1000),          -- 吃一堑长一智
  exp_happened_at DATE,
  view_count      INT DEFAULT 0,
  favorite_count  INT DEFAULT 0,
  status          TINYINT DEFAULT 1,      -- 1上架 0草稿
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted         TINYINT DEFAULT 0,
  KEY idx_user (user_id), KEY idx_cat (category_id),
  FULLTEXT KEY ft_title_desc (title, description) WITH PARSER ngram
) ENGINE=InnoDB;

CREATE TABLE `recipe_image` (
  id BIGINT PRIMARY KEY, recipe_id BIGINT NOT NULL,
  url VARCHAR(255) NOT NULL, sort INT DEFAULT 0,
  KEY idx_recipe (recipe_id)
) ENGINE=InnoDB;

CREATE TABLE `ingredient` (
  id BIGINT PRIMARY KEY, recipe_id BIGINT NOT NULL,
  type TINYINT NOT NULL,                -- 1主料 2配料
  name VARCHAR(64) NOT NULL, amount VARCHAR(32),
  KEY idx_recipe (recipe_id)
) ENGINE=InnoDB;

CREATE TABLE `recipe_step` (
  id BIGINT PRIMARY KEY, recipe_id BIGINT NOT NULL,
  step_no INT NOT NULL, content VARCHAR(500) NOT NULL,
  KEY idx_recipe (recipe_id)
) ENGINE=InnoDB;

CREATE TABLE `recipe_tool` (
  recipe_id BIGINT, tool_id BIGINT,
  PRIMARY KEY (recipe_id, tool_id)
) ENGINE=InnoDB;

CREATE TABLE `favorite` (
  user_id BIGINT, recipe_id BIGINT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, recipe_id),
  KEY idx_recipe (recipe_id)
) ENGINE=InnoDB;

CREATE TABLE `search_history` (
  id BIGINT PRIMARY KEY, user_id BIGINT NOT NULL,
  keyword VARCHAR(64) NOT NULL,
  search_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  KEY idx_user (user_id)
) ENGINE=InnoDB;

CREATE TABLE `family` (
  id BIGINT PRIMARY KEY, name VARCHAR(64) NOT NULL,
  owner_id BIGINT NOT NULL, cover_url VARCHAR(255),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP, deleted TINYINT DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE `family_member` (
  family_id BIGINT, user_id BIGINT, role VARCHAR(16) DEFAULT 'MEMBER',
  PRIMARY KEY (family_id, user_id)
) ENGINE=InnoDB;

CREATE TABLE `family_recipe` (
  family_id BIGINT, recipe_id BIGINT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (family_id, recipe_id)
) ENGINE=InnoDB;

-- 基础数据
INSERT INTO category (id,name,sort) VALUES (1,'凉菜',1),(2,'热菜',2),(3,'鱼虾',3),(4,'肉类',4),(5,'蔬菜',5);
INSERT INTO tool (id,name) VALUES (1,'炒锅'),(2,'蒸锅'),(3,'烤箱'),(4,'微波炉'),(5,'砂锅'),(6,'空气炸锅');
