#!/bin/bash
# Script to check GPIO state and start Docker container if it's stopped
# Author: GPT-5

CONTAINER_NAME="mira"      # Replace with your container name
LOG_FILE="/var/log/docker_container_check.log"
GPIO=86
GPIO_PATH="/sys/class/gpio/gpio${GPIO}"
INIT_SCRIPT="/usr/local/bin/init_4g_module.sh"  # Path to your init script
LOG_MAX_SIZE=1048576   # 1 MB = 1024 * 1024 bytes

# --- Check log file size and rotate if necessary ---
if [ -f "$LOG_FILE" ]; then
    FILE_SIZE=$(stat -c%s "$LOG_FILE")
    if [ "$FILE_SIZE" -gt "$LOG_MAX_SIZE" ]; then
        truncate -s 0 $LOG_FILE
	#mv "$LOG_FILE" "${LOG_FILE}.old"
        #echo "$(date '+%Y-%m-%d %H:%M:%S') - Log rotated, previous log saved as ${LOG_FILE}.old" > "$LOG_FILE"
    fi
fi

# --- Check GPIO direction and value ---
RUN_INIT=false

if [ -d "$GPIO_PATH" ]; then
    DIRECTION=$(cat "$GPIO_PATH/direction" 2>/dev/null)
    VALUE=$(cat "$GPIO_PATH/value" 2>/dev/null)

    # Condition 1: direction != out
    if [ "$DIRECTION" != "out" ]; then
        RUN_INIT=true
        echo "$(date '+%Y-%m-%d %H:%M:%S') - GPIO$GPIO direction is '$DIRECTION' (expected 'out')" >> "$LOG_FILE"
    fi

    # Condition 2: direction == out but value == 1
    if [ "$DIRECTION" == "out" ] && [ "$VALUE" == "1" ]; then
        RUN_INIT=true
        echo "$(date '+%Y-%m-%d %H:%M:%S') - GPIO$GPIO is output but value is HIGH (1)" >> "$LOG_FILE"
    fi
else
    RUN_INIT=true
    echo "$(date '+%Y-%m-%d %H:%M:%S') - GPIO$GPIO not exported" >> "$LOG_FILE"
fi

if [ "$RUN_INIT" = true ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Running init script..." >> "$LOG_FILE"
    bash "$INIT_SCRIPT"
    sleep 2
fi

# --- Check container status ---
STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)

if [ "$STATUS" != "running" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Container $CONTAINER_NAME is $STATUS. Starting..." >> "$LOG_FILE"
    docker start "$CONTAINER_NAME"
    if [ $? -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Successfully started $CONTAINER_NAME" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to start $CONTAINER_NAME" >> "$LOG_FILE"
    fi
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Container $CONTAINER_NAME is running" >> "$LOG_FILE"
fi
