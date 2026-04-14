#!/bin/bash
# daemon-template.sh — 通用服务保活脚本模板
# 用法: bash daemon-template.sh [status|start|stop|restart]
# 输出: running | started | stopped | failed
#
# 使用方法:
# 1. 复制到 /home/node/bin/<service>-daemon.sh
# 2. 修改 SERVICE_NAME、START_CMD 等变量
# 3. chmod +x

SERVICE_NAME="your-service"
PID_FILE="/tmp/${SERVICE_NAME}.pid"
LOG_FILE="/tmp/${SERVICE_NAME}.log"

# ========== 修改这里 ==========
START_CMD="echo 'replace with your start command'"
# ==============================

start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "running"
        return 0
    fi

    eval "$START_CMD" >> "$LOG_FILE" 2>&1

    sleep 1
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "started"
    else
        echo "failed"
        return 1
    fi
}

stop() {
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
        echo "stopped"
    else
        echo "not running"
    fi
}

case "${1:-status}" in
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "running"
        else
            start
        fi
        ;;
    start)   start ;;
    stop)    stop ;;
    restart) stop; sleep 1; start ;;
    *)       echo "Usage: $0 [status|start|stop|restart]"; exit 1 ;;
esac
