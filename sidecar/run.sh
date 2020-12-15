#!/bin/bash

echo "##### start run.sh #####"

echo "メトリクス送信を行います"
while true; do (/metric/put-metric-ecs.sh &); sleep 60; done &
while true; do (/metric/put-metric-jvm.sh &); sleep 60; done &
while true; do (/metric/put-metric-jvm-max.sh &); sleep 3600; done &
while true; do (echo "メトリクス送信中"); sleep 60; done
exec "$@"