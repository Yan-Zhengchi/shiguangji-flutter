#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
食光记 API 冒烟测试：对运行中的 docker compose 栈做端到端验证。
用法：
  python smoke_test.py                     # 全量用例（随机新用户）
  python smoke_test.py --verify-persist    # 重启栈后验证数据持久化（用上次保存的账号）
环境变量：SGJ_BASE（默认 http://localhost:8080）
"""
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid

BASE = os.environ.get("SGJ_BASE", "http://localhost:8080")
STATE_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".smoke_state.json")
PNG_1PX = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
)

PASS = 0
FAIL = 0
FAILURES = []


def check(name, cond, detail=""):
    global PASS, FAIL
    if cond:
        PASS += 1
        print("  [PASS] %s" % name)
    else:
        FAIL += 1
        FAILURES.append("%s  ->  %s" % (name, detail))
        print("  [FAIL] %s   %s" % (name, detail))


def call(method, path, body=None, token=None, headers=None, data=None, raw=False):
    url = BASE + path
    req = urllib.request.Request(url, method=method)
    h = {"Content-Type": "application/json"}
    if token:
        h["Authorization"] = "Bearer " + token
    if headers:
        h.update(headers)
    for k, v in h.items():
        req.add_header(k, v)
    payload = data if data is not None else (
        json.dumps(body, ensure_ascii=False).encode("utf-8") if body is not None else None)
    try:
        with urllib.request.urlopen(req, payload, timeout=20) as resp:
            data = resp.read()
            if raw:
                return resp.status, data          # 二进制原样返回（PNG 等）
            text = data.decode("utf-8", errors="replace")
            return resp.status, (json.loads(text) if text else None)
    except urllib.error.HTTPError as e:
        text = e.read().decode("utf-8", errors="replace")
        try:
            return e.code, json.loads(text)
        except Exception:
            return e.code, text
    except Exception as e:
        return -1, str(e)


def code_of(res):
    return res.get("code") if isinstance(res, dict) else None


def ok(res):
    return isinstance(res, dict) and res.get("code") == 0


def multipart_upload(token, filename, content, content_type):
    boundary = "----SmokeTest" + uuid.uuid4().hex
    head = ("--%s\r\nContent-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\n"
            "Content-Type: %s\r\n\r\n" % (boundary, filename, content_type)).encode("utf-8")
    body = head + content + ("\r\n--%s--\r\n" % boundary).encode("utf-8")
    return call("POST", "/api/v1/uploads/image", token=token,
                headers={"Content-Type": "multipart/form-data; boundary=" + boundary}, data=body)


def wait_healthy(timeout=180):
    print("== 等待服务就绪 ==")
    start = time.time()
    while time.time() - start < timeout:
        status, res = call("GET", "/actuator/health")
        if status == 200 and isinstance(res, dict) and res.get("status") == "UP":
            check("actuator health UP", True)
            return True
        time.sleep(3)
    check("actuator health UP", False, "超时 %ss" % timeout)
    return False


def main():
    print("食光记冒烟测试  BASE=%s" % BASE)

    if "--verify-persist" in sys.argv:
        verify_persist()
        summary()
        return

    if not wait_healthy():
        summary()
        sys.exit(1)

    suffix = uuid.uuid4().hex[:8]
    u1 = "chef_" + suffix
    u2 = "foodie_" + suffix
    pwd = "Pass123456"

    # ---------- 认证 ----------
    print("== 认证 ==")
    st, res = call("POST", "/api/v1/auth/register", {
        "username": u1, "password": pwd, "nickname": "主厨一号", "phone": "138%08d" % (int(suffix, 16) % 10 ** 8)})
    check("注册成功", ok(res), str(res))
    tok1 = res["data"]["accessToken"] if ok(res) else None
    ref1 = res["data"]["refreshToken"] if ok(res) else None
    uid1 = res["data"]["userId"] if ok(res) else None
    check("注册返回双 Token", tok1 and ref1, str(res)[:200])

    st, res = call("POST", "/api/v1/auth/register", {
        "username": u1, "password": pwd, "nickname": "重复"})
    check("重复注册 → 20002", code_of(res) == 20002, str(res))

    st, res = call("POST", "/api/v1/auth/login", {"username": u1, "password": "wrong!"})
    check("错误密码 → 20001", code_of(res) == 20001, str(res))

    st, res = call("POST", "/api/v1/auth/login", {"username": u1, "password": pwd})
    check("登录成功", ok(res), str(res))
    tok1 = res["data"]["accessToken"]
    ref1 = res["data"]["refreshToken"]

    st, res = call("GET", "/api/v1/auth/me", token=tok1)
    check("GET /auth/me", ok(res) and res["data"]["username"] == u1, str(res))

    st, res = call("GET", "/api/v1/auth/me")
    check("无 Token 访问 /auth/me → 40100", code_of(res) == 40100, str(res))

    # ---------- 分类 ----------
    print("== 分类 ==")
    st, res = call("GET", "/api/v1/categories")
    check("分类列表 5 项", ok(res) and len(res["data"]) == 5, str(res)[:200])

    # ---------- 上传 ----------
    print("== 上传 ==")
    st, res = multipart_upload(tok1, "test.png", PNG_1PX, "image/png")
    check("图片上传返回 URL", ok(res) and str(res.get("data", "")).startswith("/uploads/"), str(res))
    upload_url = res["data"] if ok(res) else None
    if upload_url:
        st2, body = call("GET", upload_url, raw=True)
        check("上传的图片可访问", st2 == 200 and body == PNG_1PX, "status=%s" % st2)
    st, res = multipart_upload(tok1, "bad.txt", b"hello", "text/plain")
    check("非图片上传被拒", not ok(res), str(res))

    # ---------- 发布菜谱 ----------
    print("== 菜谱 ==")
    publish_body = {
        "title": "经典红烧肉",
        "categoryId": 2,
        "coverUrl": upload_url,
        "images": [upload_url],
        "description": "肥而不腻、入口即化的经典家常菜",
        "servings": 2,
        "cookMinutes": 90,
        "difficulty": 2,
        "ingredients": [
            {"type": 1, "name": "带皮五花肉", "amount": "500 克"},
            {"type": 1, "name": "黄冰糖", "amount": "30 克"},
            {"type": 2, "name": "姜片", "amount": "5 片"}],
        "toolIds": [1, 2, 5],
        "steps": ["五花肉切块冷水下锅焯水", "黄冰糖小火炒至琥珀色", "加水炖煮一小时收汁"],
        "tips": "炒糖色全程小火",
        "notes": "焯水要冷水下锅\n糖色炒过头会发苦",
        "experience": {"text": "第一次做水放多了", "happenedAt": "2026-08-20"},
    }
    st, res = call("POST", "/api/v1/recipes", publish_body, token=tok1)
    check("发布菜谱", ok(res), str(res))
    rid = res["data"] if ok(res) else None

    st, res = call("POST", "/api/v1/recipes", {"categoryId": 2, "steps": ["x"]}, token=tok1)
    check("缺标题 → 40010", code_of(res) == 40010, str(res))

    st, res = call("POST", "/api/v1/recipes", publish_body)
    check("未登录发布 → 40100", code_of(res) == 40100, str(res))

    # ---------- 详情 ----------
    print("== 详情 ==")
    st, res = call("GET", "/api/v1/recipes/%s" % rid)
    check("匿名可看详情", ok(res), str(res)[:200])
    d = res.get("data", {}) if ok(res) else {}
    check("详情字段完整",
          d.get("title") == "经典红烧肉" and d.get("authorName") == "主厨一号"
          and d.get("difficulty") == "中等" and d.get("servings") == "2 人份"
          and d.get("categoryName") == "热菜",
          json.dumps(d, ensure_ascii=False)[:300])
    check("食材/步骤/工具/注意事项",
          len(d.get("ingredients") or []) == 3
          and (d.get("ingredients") or [{}])[0].get("type") == "主料"
          and len(d.get("steps") or []) == 3
          and len(d.get("tools") or []) == 3
          and len(d.get("notes") or []) == 2,
          json.dumps(d, ensure_ascii=False)[:300])
    check("吃一堑长一智卡", (d.get("experience") or {}).get("text") == "第一次做水放多了",
          str(d.get("experience")))
    check("浏览量计数", (d.get("viewCount") or 0) >= 1, str(d.get("viewCount")))

    st, res = call("GET", "/api/v1/recipes/999999")
    check("不存在 → 30001", code_of(res) == 30001, str(res))

    # ---------- 首页/热门 ----------
    print("== 首页/热门 ==")
    st, res = call("GET", "/api/v1/recipes/home?page=1&size=6")
    check("首页瀑布流含新菜谱", ok(res) and any(c["title"] == "经典红烧肉" for c in res["data"]),
          str(res)[:200])
    card = next((c for c in res["data"] if c["title"] == "经典红烧肉"), {})
    check("卡片结构(id/author/favorite/imgRatio)",
          card.get("id") and card.get("authorName") and "favoriteCount" in card and card.get("imgRatio"),
          str(card))

    st, res = call("GET", "/api/v1/recipes/home?categoryId=5&page=1")
    check("分类过滤（蔬菜类为空）", ok(res) and len(res["data"]) == 0, str(res)[:150])

    st, res = call("GET", "/api/v1/recipes/hot?limit=10")
    check("热门榜", ok(res) and any(c.get("title") == "经典红烧肉" for c in res["data"]), str(res)[:200])

    # ---------- 搜索 ----------
    print("== 搜索 ==")
    st, res = call("GET", "/api/v1/search?keyword=" + urllib.request.quote("红烧"), token=tok1)
    check("关键词搜索命中", ok(res) and any(c["title"] == "经典红烧肉" for c in res["data"]), str(res)[:200])

    st, res = call("GET", "/api/v1/search?keyword=" + urllib.request.quote("不存在的东西xyz"))
    check("无结果返回空列表", ok(res) and len(res["data"]) == 0, str(res)[:150])

    st, res = call("GET", "/api/v1/search/hot")
    check("热搜词", ok(res) and "红烧" in (res["data"] or []), str(res))

    st, res = call("GET", "/api/v1/search/history", token=tok1)
    check("搜索历史", ok(res) and "红烧" in (res["data"] or []), str(res))

    st, res = call("DELETE", "/api/v1/search/history", token=tok1)
    st, res = call("GET", "/api/v1/search/history", token=tok1)
    check("清空历史", ok(res) and len(res["data"]) == 0, str(res))

    # ---------- 收藏 ----------
    print("== 收藏 ==")
    st, res = call("POST", "/api/v1/favorites/%s" % rid, token=tok1)
    check("收藏", ok(res), str(res))
    st, res = call("POST", "/api/v1/favorites/%s" % rid, token=tok1)
    check("重复收藏 → 30004", code_of(res) == 30004, str(res))

    st, res = call("GET", "/api/v1/favorites?page=1", token=tok1)
    check("收藏列表", ok(res) and len(res["data"]) == 1, str(res)[:200])

    st, res = call("GET", "/api/v1/recipes/%s" % rid, token=tok1)
    check("详情收藏状态=true", ok(res) and res["data"].get("favorite") is True, str(res.get("data", {}))[:150])

    # ---------- 个人 ----------
    print("== 个人 ==")
    st, res = call("GET", "/api/v1/users/profile", token=tok1)
    stats = res.get("data", {}).get("stats", {}) if ok(res) else {}
    check("统计(菜谱1/收藏1/家庭0)",
          int(stats.get("recipeCount", 0)) == 1 and int(stats.get("favoriteCount", 0)) == 1
          and int(stats.get("familyCount", 0)) == 0, str(res)[:250])

    st, res = call("PUT", "/api/v1/users/profile", {"nickname": "金牌主厨"}, token=tok1)
    check("改昵称", ok(res) and res["data"]["nickname"] == "金牌主厨", str(res)[:200])

    st, res = call("GET", "/api/v1/users/recipes?page=1", token=tok1)
    check("个人菜谱", ok(res) and len(res["data"]) == 1, str(res)[:150])

    # ---------- 编辑/越权 ----------
    print("== 编辑/越权 ==")
    publish_body["title"] = "秘制红烧肉"
    st, res = call("PUT", "/api/v1/recipes/%s" % rid, publish_body, token=tok1)
    check("编辑自己的菜谱", ok(res), str(res))
    st, res = call("GET", "/api/v1/recipes/%s" % rid)
    check("编辑后标题已更新", ok(res) and res["data"]["title"] == "秘制红烧肉", str(res)[:150])

    st, res = call("POST", "/api/v1/auth/register", {
        "username": u2, "password": pwd, "nickname": "吃货二号"})
    tok2 = res["data"]["accessToken"] if ok(res) else None
    st, res = call("PUT", "/api/v1/recipes/%s" % rid, publish_body, token=tok2)
    check("他人编辑 → 30002", code_of(res) == 30002, str(res))

    # ---------- 家庭 ----------
    print("== 家庭 ==")
    st, res = call("POST", "/api/v1/families", {"name": "小禾家"}, token=tok1)
    check("创建家庭", ok(res), str(res))
    fid = res["data"]["id"] if ok(res) else None

    st, res = call("GET", "/api/v1/families", token=tok1)
    check("家庭列表", ok(res) and len(res["data"]) == 1 and res["data"][0]["memberCount"] == 1,
          str(res)[:250])

    st, res = call("POST", "/api/v1/families/%s/members" % fid, {"username": u2}, token=tok1)
    check("按用户名邀请成员", ok(res), str(res))
    st, res = call("POST", "/api/v1/families/%s/members" % fid, {"username": u2}, token=tok1)
    check("重复邀请 → 40002", code_of(res) == 40002, str(res))
    st, res = call("POST", "/api/v1/families/%s/members" % fid, {"username": "no_such_user"}, token=tok1)
    check("邀请不存在用户 → 20003", code_of(res) == 20003, str(res))

    st, res = call("POST", "/api/v1/families/%s/recipes/%s" % (fid, rid), token=tok1)
    check("加入家庭菜谱", ok(res), str(res))
    st, res = call("GET", "/api/v1/families/%s/recipes" % fid, token=tok2)
    check("成员可见家庭菜谱", ok(res) and len(res["data"]) == 1
          and res["data"][0]["title"] == "秘制红烧肉", str(res)[:250])

    st, res = call("DELETE", "/api/v1/families/%s/recipes/%s" % (fid, rid), token=tok2)
    check("移除家庭菜谱", ok(res), str(res))
    st, res = call("GET", "/api/v1/families/%s/recipes" % fid, token=tok2)
    check("移除后为空", ok(res) and len(res["data"]) == 0, str(res))

    st, res = call("GET", "/api/v1/families/%s/recipes" % fid, token=None)
    check("非成员/未登录 → 40100", code_of(res) == 40100, str(res))

    # ---------- Token 续期与登出 ----------
    print("== Token 续期/登出 ==")
    st, res = call("POST", "/api/v1/auth/refresh", {"refreshToken": ref1})
    check("refresh 换新双 Token", ok(res) and res["data"]["accessToken"], str(res)[:200])
    new_tok = res["data"]["accessToken"] if ok(res) else None
    new_ref = res["data"]["refreshToken"] if ok(res) else None

    st, res = call("POST", "/api/v1/auth/refresh", {"refreshToken": ref1})
    check("旧 refreshToken 已旋转失效 → 40100", code_of(res) == 40100, str(res))

    st, res = call("POST", "/api/v1/auth/logout", {"refreshToken": new_ref or ""}, token=new_tok)
    check("登出", ok(res), str(res))
    st, res = call("GET", "/api/v1/auth/me", token=new_tok)
    check("登出后旧 Token → 40100", code_of(res) == 40100, str(res))

    # 重新登录保存状态（供持久化验证）
    st, res = call("POST", "/api/v1/auth/login", {"username": u1, "password": pwd})
    tok1 = res["data"]["accessToken"] if ok(res) else tok1
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump({"username": u1, "password": pwd, "recipeId": rid, "nickname": "金牌主厨"}, f)

    summary()


def verify_persist():
    print("== 持久化验证（compose down/up 后） ==")
    if not os.path.exists(STATE_FILE):
        check("状态文件存在", False, "先跑全量用例")
        return
    state = json.load(open(STATE_FILE, encoding="utf-8"))
    if not wait_healthy():
        return
    st, res = call("POST", "/api/v1/auth/login",
                   {"username": state["username"], "password": state["password"]})
    check("老账号仍可登录（用户数据持久化）", ok(res), str(res)[:200])
    tok = res["data"]["accessToken"] if ok(res) else None

    rid = state.get("recipeId")
    st, res = call("GET", "/api/v1/recipes/%s" % rid)
    check("菜谱仍在（MySQL 数据持久化）",
          ok(res) and res.get("data", {}).get("title") == "秘制红烧肉", str(res)[:250])

    st, res = call("GET", "/api/v1/users/profile", token=tok)
    check("昵称修改已持久化", ok(res) and res.get("data", {}).get("nickname") == state.get("nickname"),
          str(res)[:200])

    st, res = call("GET", "/api/v1/categories")
    check("分类种子数据仍在", ok(res) and len(res.get("data") or []) == 5, str(res)[:150])


def summary():
    print("\n========== 结果 ==========")
    print("PASS: %d   FAIL: %d" % (PASS, FAIL))
    if FAILURES:
        print("失败用例：")
        for f in FAILURES:
            print("  - %s" % f)
    sys.exit(1 if FAIL else 0)


if __name__ == "__main__":
    main()
