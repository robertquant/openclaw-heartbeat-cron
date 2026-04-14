---
name: openclaw-heartbeat-cron
description: OpenClaw 心跳与定时任务配置指南。当用户提到 heartbeat、cron、定时任务、心跳保活、HEARTBEAT.md、每日巡检、定时发消息、定时检查、periodic task、scheduled task 时触发。提供完整的 HEARTBEAT.md 配置模板、cron 任务设置方法、服务保活脚本和日夜分工策略。
---

# OpenClaw 心跳与 Cron 定时任务

## 核心概念

OpenClaw 两种定时机制：

| 机制 | 适用场景 | 特点 |
|------|---------|------|
| **Heartbeat** | 多任务批量巡检、需要上下文 | 跟随主 session，共享历史 |
| **Cron** | 精确定时、独立任务、隔离运行 | 独立 session，精确触发 |

详细对比见 [references/modes.md](references/modes.md)

## 快速开始

### 1. 创建 HEARTBEAT.md

在 workspace 根目录创建 `HEARTBEAT.md`，OpenClaw 每次心跳会自动读取。

**最小模板：**
```markdown
# HEARTBEAT.md - 定期检查任务

## 0️⃣ 服务保活

每次心跳执行：
```bash
bash /home/node/bin/my-daemon.sh
```

## 1️⃣ 主要任务

[你的定期任务描述]
```

### 2. 配置心跳间隔

在 OpenClaw 配置文件中设置心跳频率：
- 高频活跃：30-60 分钟
- 白天休息：2-4 小时
- 低频检查：4-8 小时

### 3. 添加 Cron 任务（可选）

用于精确定时任务（如每日早报）。

## 服务保活脚本

每类需要保活的服务写一个 daemon 脚本，放到 `/home/node/bin/`。

**标准模板**（[scripts/daemon-template.sh](scripts/daemon-template.sh)）：

```bash
#!/bin/bash
# <service-name>-daemon.sh — 保活脚本
# 输出: running | started | stopped | failed

PID_FILE="/tmp/<service>.pid"

start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "running"; return 0
    fi
    # 启动命令
    your-command -f "$PID_FILE" >> /tmp/<service>.log 2>&1
    sleep 1
    [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null && echo "started" || echo "failed"
}

case "${1:-status}" in
    status) [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null && echo "running" || start ;;
    start) start ;;
    stop) kill "$(cat "$PID_FILE")" 2>/dev/null; rm -f "$PID_FILE"; echo "stopped" ;;
    restart) $0 stop; sleep 1; $0 start ;;
esac
```

## HEARTBEAT.md 完整模板

参考 [references/heartbeat-template.md](references/heartbeat-template.md) 获取带日夜分工、多任务类型的完整模板。

## 常见任务模式

### API 巡检
```bash
curl -s -H "Authorization: Bearer $API_KEY" https://api.example.com/dashboard
```

### 代理保活（Shadowsocks）
```bash
bash /home/node/bin/ss-daemon.sh
```

### FRP 内网穿透保活
```bash
bash /home/node/bin/frpc-daemon.sh
```

### 定时发消息
在心跳中判断时间后，用 `message` 工具发送：
```
message(action=send, accountId="main", target="user:xxx", message="...")
```
⚠️ 心跳时无 inbound 上下文，必须显式传 `accountId`。

### 记忆治理
每周检查记忆系统健康，清理过期记录。见 [references/memory-checklist.md](references/memory-checklist.md)

## 状态追踪

用 JSON 文件记录上次检查时间，避免重复执行：
```json
{
  "lastChecks": {
    "forum": 1744514100,
    "news": 1744514100
  }
}
```

每次心跳对比时间戳决定是否需要执行。

## 日夜分工策略

适合资源有限的 Agent：
- **工作日白天**：低频心跳，只做必要回复
- **工作日夜间 + 周末**：高频心跳，主动互动、创作
- 详细模板见 [references/heartbeat-template.md](references/heartbeat-template.md)

## 注意事项

1. **HEARTBEAT.md 保持精简** — 心跳每次都读取，太大会浪费 token
2. **避免重复执行** — 用状态文件追踪上次检查时间
3. **发消息必须带 accountId** — 心跳无 inbound 上下文
4. **频率限制** — 注意目标 API 的 rate limit
5. **失败静默** — 非关键任务失败不要反复重试
