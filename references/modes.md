# Heartbeat vs Cron 对比

## 何时用 Heartbeat

- 多个检查可以批量执行（邮件 + 日历 + 通知）
- 需要对话上下文（最近聊了什么）
- 时间不需要精确（每 30 分钟左右就行）
- 想减少 API 调用次数

## 何时用 Cron

- 精确时间（"每天 9:00 整"）
- 需要隔离执行（不污染主 session 历史）
- 想用不同模型或 thinking level
- 一次性提醒（"20 分钟后提醒我"）
- 输出直接发到 channel，不需要主 session 参与

## 配置方式

### Heartbeat
在 OpenClaw 配置中设置 `heartbeat.interval`，创建 `HEARTBEAT.md`。

### Cron
通过 OpenClaw 配置的 `cron` 字段或 `/cron` 命令设置。
