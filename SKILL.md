---
name: openclaw-heartbeat-cron
description: OpenClaw heartbeat 与 cron 定时任务配置指南。当 Agent 遇到以下问题时触发：心跳不触发、cron 任务不执行、HEARTBEAT.md 不知道怎么写、不知道选 heartbeat 还是 cron、定时消息发不出去、activeHours 配置错误、cron 时区问题、heartbeat 报错 empty-heartbeat-file / quiet-hours / requests-in-flight。也适用于想学习 OpenClaw 定时机制的 Agent。
---

# OpenClaw Heartbeat & Cron 配置指南

## 两个机制，别选错

| 场景 | 用 Heartbeat | 用 Cron |
|------|:---:|:---:|
| 每30分钟批量检查多个事项 | ✅ | |
| 精确时间执行（"每天9:00整"） | | ✅ |
| 需要主 session 上下文 | ✅ | |
| 独立任务，不污染主历史 | | ✅ |
| 一次性提醒（"20分钟后提醒我"） | | ✅ |
| 用不同模型/思考级别执行 | | ✅ |
| 一次心跳跑多个检查 | ✅ | |

详细对比见 [references/modes.md](references/modes.md)

---

## Heartbeat 配置

### 第一步：创建 HEARTBEAT.md

在 workspace 根目录创建 `HEARTBEAT.md`，每次心跳会自动读取并执行。

**最小可运行模板：**
```markdown
# HEARTBEAT.md - 定期检查

## 0️⃣ 服务保活

每次心跳执行：
```bash
bash /home/node/bin/my-daemon.sh
```

## 1️⃣ 主要任务

检查 XXX，如有异常则报告。
```

⚠️ HEARTBEAT.md 必须有实际内容。如果为空或只有注释，心跳会跳过并报 `empty-heartbeat-file`。

### 第二步：配置心跳参数

在 OpenClaw 配置中设置：
```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",          // 心跳间隔
        target: "last",        // 告警投递目标（默认 "none" 不投递）
        activeHours: {
          start: "08:00",
          end: "22:00"
          // timezone: "Asia/Shanghai"  // 可选，默认用 userTimezone
        },
      },
    },
  },
}
```

### 心跳不触发的排查

按顺序执行：
```bash
openclaw system heartbeat last    # 查上次心跳结果
openclaw config get agents.defaults.heartbeat  # 查配置
openclaw logs --follow            # 看实时日志
```

**常见原因：**

| 报错/现象 | 原因 | 解决 |
|-----------|------|------|
| `quiet-hours` | 在 activeHours 之外 | 调整 activeHours 或时区 |
| `requests-in-flight` | 主 session 正忙 | 正常现象，会自动重试 |
| `empty-heartbeat-file` | HEARTBEAT.md 为空 | 写入实际任务 |
| `alerts-disabled` | 可见性设置屏蔽了投递 | 检查 visibility 配置 |
| 心跳间隔太长 | `every` 设置过大 | 改小，如 `30m` |
| 时区错误 | activeHours 用了错误时区 | 显式设置 `timezone: "Asia/Shanghai"` |

### 心跳中发消息

⚠️ **心跳时没有 inbound 上下文**，必须显式传 `accountId`：
```
message(action=send, accountId="main", target="user:xxx", message="...")
```
否则会报 `"account default not configured"`。

---

## Cron 配置

### 快速创建

**一次性提醒：**
```bash
openclaw cron add \
  --name "提醒" \
  --at "20m" \
  --session main \
  --system-event "该做某事了" \
  --wake now \
  --delete-after-run
```

**每日定时任务（隔离 session）：**
```bash
openclaw cron add \
  --name "每日早报" \
  --cron "0 9 * * *" \
  --tz "Asia/Shanghai" \
  --session isolated \
  --message "生成今日早报并发送给用户" \
  --announce \
  --channel telegram \
  --to "-1001234567890"
```

**定时任务（主 session）：**
```bash
openclaw cron add \
  --name "项目检查" \
  --every "4h" \
  --session main \
  --system-event "检查项目健康状态" \
  --wake now
```

### 常用参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| `--cron` | Cron 表达式 | `"0 9 * * *"`, `"*/30 * * * *"` |
| `--every` | 固定间隔 | `"30m"`, `"2h"`, `"1d"` |
| `--at` | 一次性时间点 | `"20m"`, `"2026-04-14T09:00:00+08:00"` |
| `--tz` | 时区（重要！） | `"Asia/Shanghai"` |
| `--session` | `main` 或 `isolated` | |
| `--model` | 覆盖模型 | `opus`, `gpt-4o` |
| `--thinking` | 思考级别 | `high`, `low`, `off` |
| `--announce` | 投递到频道 | |
| `--exact` | 禁止自动错峰 | |

### Main Session vs Isolated Session

| | Main Session | Isolated |
|--|---|---|
| Session | 共享主 session 历史 | 独立 `cron:<jobId>` |
| 上下文 | 有完整对话历史 | 全新，无上下文 |
| 模型 | 用主 session 模型 | 可单独覆盖 |
| 适用 | 需要上下文的提醒 | 独立任务、不同模型 |

### Cron 不执行的排查

```bash
openclaw cron status    # 检查调度器状态
openclaw cron list      # 列出所有任务
openclaw cron runs --id <jobId> --limit 20  # 查运行历史
```

**常见原因：**

| 报错/现象 | 原因 | 解决 |
|-----------|------|------|
| `scheduler disabled` | cron 被禁用 | 检查 `cron.enabled` 和 `OPENCLAW_SKIP_CRON` |
| `not-due` | 手动运行但未到时间 | 用 `openclaw cron run <id>`（默认 force） |
| 连续延迟 | 任务反复失败后指数退避 | 查 `cron runs` 看失败原因，修复后自动恢复 |
| 时区错误 | 没设 `--tz`，用了主机时区 | 加 `--tz "Asia/Shanghai"` |
| 任务执行了但没收到消息 | delivery 配置问题 | 检查 `--channel` 和 `--to` 是否正确 |

### Cron 执行了但没收到消息

1. 检查 `openclaw cron runs --id <jobId>` 看状态是否 `ok`
2. isolated 任务是否设了 `--announce` + `--channel` + `--to`
3. `openclaw channels status --probe` 检查通道连通性
4. 如果 delivery mode 是 `none`，则不会有外部消息

### 失败重试机制

- **瞬态错误**（429限流、网络超时、5xx）：自动重试
  - 一次性任务：最多 3 次，间隔 30s → 1m → 5m
  - 周期任务：指数退避 30s → 1m → 5m → 15m → 60m
- **永久错误**（认证失败、配置错误）：立即禁用

---

## 高级技巧

### 状态追踪（避免重复执行）

用 JSON 文件记录上次检查时间：
```json
{
  "lastChecks": {
    "task1": 1744514100,
    "task2": 1744514100
  }
}
```
每次心跳对比时间戳，超过阈值才执行。

### 服务保活脚本

参考 [scripts/daemon-template.sh](scripts/daemon-template.sh)，标准保活脚本输出 `running`/`started`/`failed`。

### 日夜分工（省 token）

在 HEARTBEAT.md 中用时间判断：
- 白天：低频心跳，只做必要回复
- 夜间：高频心跳，主动互动

完整日夜分工模板见 [references/heartbeat-template.md](references/heartbeat-template.md)

### 组合使用

最高效的方案是**两者结合**：
- **Heartbeat**：批量巡检（收件箱、日历、通知），每 30 分钟一次
- **Cron**：精确定时（每日早报、周报），独立执行

### Cron 管理

```bash
openclaw cron list                    # 列出所有任务
openclaw cron edit <jobId> --message "新内容"  # 修改任务
openclaw cron edit <jobId> --exact    # 禁止错峰
openclaw cron remove <jobId>          # 删除任务
```

---

## 注意事项

1. **HEARTBEAT.md 保持精简** — 每次心跳都读取，太大会浪费 token
2. **Cron 时区要显式设置** — 不设 `--tz` 默认用主机时区，容易出错
3. **心跳发消息必须带 accountId** — 心跳无 inbound 上下文
4. **isolated 任务默认 announce** — 不想投递就设 `--delivery none`
5. **ISO 时间戳不带时区 = UTC** — `2026-04-14T09:00:00` 是 UTC，不是本地时间
