# Heartbeat vs Cron 详解

## Heartbeat 本质

Heartbeat 是 OpenClaw 定期在主 session 中触发一次 agent turn。Agent 读取 HEARTBEAT.md，执行其中的任务，如果没什么事就回复 `HEARTBEAT_OK`。

### 心跳生命周期

1. Gateway 每 N 分钟（默认 30m）触发一次
2. 检查 `activeHours`，不在范围内则跳过（`quiet-hours`）
3. 检查主 session 是否空闲，忙则延迟（`requests-in-flight`）
4. 读取 HEARTBEAT.md 内容
5. 如果 HEARTBEAT.md 为空，跳过（`empty-heartbeat-file`）
6. Agent 执行任务并回复

### 心跳能做什么

- 读取文件、执行 shell 命令
- 调用 API（curl）
- 用 message 工具发消息（需显式传 accountId）
- 更新文件、整理记忆

### 心跳不能做什么

- 不能用不同的模型（共享主 session 模型）
- 不能精确到秒级触发
- 不能完全隔离（共享主 session 历史）

---

## Cron 本质

Cron 是 Gateway 内置的调度器，持久化在 `~/.openclaw/cron/jobs.json`。

### Cron 两种执行模式

**Main session（system event）：**
- 向主 session 注入一个系统事件
- 下次心跳时 Agent 会看到这个事件并处理
- 适合需要上下文的提醒

**Isolated（agent turn）：**
- 在独立 session `cron:<jobId>` 中执行
- 每次都是全新 session，无历史上下文
- 可覆盖模型和思考级别
- 默认 announce（投递结果到频道）

### Cron 调度细节

- 支持 cron 表达式（5字段/6字段）+ 固定间隔 + 一次性时间点
- 整点任务默认自动错峰 0-5 分钟，`--exact` 可禁用
- ISO 时间戳不带时区 = UTC
- 不设 `--tz` 默认用 Gateway 主机时区

---

## 选型决策树

```
需要精确时间？
  YES → Cron
  NO  ↓

需要独立 session / 不同模型？
  YES → Cron (isolated)
  NO  ↓

能和其他检查一起批量做？
  YES → Heartbeat
  NO  → Cron

一次性提醒？
  YES → Cron (--at)
  NO  → 看复杂度
```

---

## 最佳实践

1. **批量巡检用 Heartbeat** — 一次心跳跑 5 个检查，比 5 个 cron 便宜
2. **精确定时用 Cron** — 每天早报、周报、定时提醒
3. **重任务用 Cron isolated** — 可用便宜模型，不污染主历史
4. **两者结合** — Heartbeat 日常巡检 + Cron 精确定时
