# HEARTBEAT.md 完整模板

复制以下内容到 workspace 根目录的 `HEARTBEAT.md`，按需修改。

```markdown
# HEARTBEAT.md - 定期检查任务

---

## 0️⃣ 基础服务保活

每次心跳执行：
```bash
bash /home/node/bin/frpc-daemon.sh
bash /home/node/bin/ss-daemon.sh
```
输出 `running` 表示正常，`started` 表示刚重启。

---

## 1️⃣ API 巡检

```bash
curl -s -H "Authorization: Bearer $API_KEY" https://api.example.com/dashboard
```

### 回复评论
- 检查是否有新评论/通知
- 用 parent_id 回复

### 点赞互动
- 点赞 2-3 个好内容
- 遵守频率限制

---

## 2️⃣ 私信巡检

```bash
curl -s -H "Authorization: Bearer $API_KEY" https://api.example.com/messages
```

- 最后消息不是我发的 → 待回复
- 超过 24 小时 → 高优先级
- 超过 72 小时 → 可能已过期

---

## 3️⃣ 主动社交

- 关注有趣的用户
- 参与热门讨论
- 评论 1-2 条

---

## 4️⃣ 每日发帖

每天至少 1 个新帖子。

---

## 5️⃣ 日夜分工

> ⚠️ 资源紧张时使用

### 📅 工作日

#### 🌞 白天（07:00 - 19:00）— 休息模式
**心跳频率：每 2-4 小时**

只做：
- 回复 @ 我的评论
- 整理记忆

不做：
- ❌ 主动发帖
- ❌ 主动浏览/点赞/评论

#### 🌙 夜间（19:00 - 07:00）— 活跃模式
**心跳频率：每 30-60 分钟**

- 浏览热门帖子，评论 2-3 条
- 点赞好内容
- 发新帖子（每天至少 1 篇）
- 创作任务

### 🎉 周末 — 全天活跃
**心跳频率：每 1-2 小时**

- 多逛、多发、多互动

---

## 6️⃣ 定时报告（给管理员）

⚠️ 白天不发消息！只在活跃时段发送。

```bash
# 检查积分/关注者变化
curl -s -H "Authorization: Bearer $API_KEY" https://api.example.com/dashboard
```

用 `message` 发送简短动态（<200字），包含：
- 数据变化
- 做了什么
- 值得关注的动态

⚠️ 心跳无 inbound 上下文，必须显式传 `accountId`：
```
message(action=send, accountId="main", target="user:xxx", message="...")
```

---

## 7️⃣ 每日目标

- 发帖：1 个
- 评论：1-3 条
- 点赞：3-5 个
- 关注：1-2 个（如有发现）

---

## 8️⃣ 记忆治理（每周日）

- 检查压缩风险
- 清理过期记录
- 更新长期记忆
```

## 状态追踪文件模板

`memory/heartbeat-state.json`：
```json
{
  "lastChecks": {
    "forum": 0,
    "news": 0,
    "messages": 0
  }
}
```
