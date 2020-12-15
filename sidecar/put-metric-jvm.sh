#!/bin/bash

echo "##### start put-metric-jvm.sh #####"

function put_metics_data() {
    for METRIC_NAME in "${!METRIC_RES_LIST[@]}"; do
        aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name "${METRIC_NAME}" --value "${METRIC_RES_LIST[${METRIC_NAME}]}" --unit "${UNIT_TYPE_LIST[${METRIC_NAME}]}"
    done
}

# ECSメタデータエンドポイントのURLを変数にセットする
TASK_META_ENDPOINT=${ECS_CONTAINER_METADATA_URI_V4}/task

# メタデータのJSONを変数にセットする
TASK_META_JSON=`curl -s $TASK_META_ENDPOINT`

TASK_ARN=`echo $TASK_META_JSON | jq -r .TaskARN`
TASK_NAME=`echo $TASK_ARN | tr '/' '\n' | tail -1`
# サービスまたはタスク定義からタスク起動時にタグを伝播させるのが前提
# メタデータから取得出来ない情報をタグから取得する
SERVICE_NAME=`aws ecs list-tags-for-resource --resource-arn $TASK_ARN | jq '.tags[] | select(.key == "aws:ecs:serviceName") | .value'`
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
JMX_PORT=10048
JMXCLIENT_PATH=/metric/cmdline-jmxclient-0.10.3.jar
JMX_CMD="java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT"

# JVMのメトリクスを取得しメトリクス名をキーにした連想配列に詰める
declare -A METRIC_RES_LIST=(
    ["JmxGCG1OldCollectionCount"]=`$JMX_CMD "java.lang:name=G1 Old Generation,type=GarbageCollector" CollectionCount 2>&1 | cut -d' ' -f6`
    ["JmxGCG1OldCollectionTime"]=`$JMX_CMD "java.lang:name=G1 Old Generation,type=GarbageCollector" CollectionTime 2>&1 | cut -d' ' -f6`
    ["JmxGCG1YoungCollectionCount"]=`$JMX_CMD "java.lang:name=G1 Young Generation,type=GarbageCollector" CollectionCount 2>&1 | cut -d' ' -f6`
    ["JmxGCG1YoungCollectionTime"]=`$JMX_CMD "java.lang:name=G1 Young Generation,type=GarbageCollector" CollectionTime 2>&1 | cut -d' ' -f6`
    ["JmxHeapMemoryUsageCommitted"]=`$JMX_CMD "java.lang:type=Memory" HeapMemoryUsage  2>&1 | grep committed | cut -d' ' -f2`
    ["JmxHeapMemoryUsageUsed"]=`$JMX_CMD "java.lang:type=Memory" HeapMemoryUsage  2>&1 | grep used | cut -d' ' -f2`
    ["JmxNonHeapMemoryUsageCommitted"]=`$JMX_CMD "java.lang:type=Memory" NonHeapMemoryUsage  2>&1 | grep committed | cut -d' ' -f2`
    ["JmxNonHeapMemoryUsageUsed"]=`$JMX_CMD "java.lang:type=Memory" NonHeapMemoryUsage  2>&1 | grep used | cut -d' ' -f2`
    ["JmxMetaspaceCommitted"]=`$JMX_CMD "java.lang:name=Metaspace,type=MemoryPool" Usage 2>&1 | grep committed | cut -d' ' -f2`
    ["JmxMetaspaceUsed"]=`$JMX_CMD "java.lang:name=Metaspace,type=MemoryPool" Usage 2>&1 | grep used | cut -d' ' -f2`
    ["JmxConnectionPoolActiveConnections"]=`$JMX_CMD "com.zaxxer.hikari:type=Pool (HikariPool-1)" ActiveConnections 2>&1 | cut -d' ' -f6`
    ["JmxConnectionPoolIdleConnections"]=`$JMX_CMD "com.zaxxer.hikari:type=Pool (HikariPool-1)" IdleConnections 2>&1 | cut -d' ' -f6`
    ["JmxConnectionPoolTotalConnections"]=`$JMX_CMD "com.zaxxer.hikari:type=Pool (HikariPool-1)" TotalConnections 2>&1 | cut -d' ' -f6`
    ["JmxConnectionPoolThreadsAwaitingConnection"]=`$JMX_CMD "com.zaxxer.hikari:type=Pool (HikariPool-1)" ThreadsAwaitingConnection 2>&1 | cut -d' ' -f6`
)
# メトリクス名をキーをメトリクスの単位を連想配列に詰める
declare -A UNIT_TYPE_LIST=(
    ["JmxGCG1OldCollectionCount"]=Count
    ["JmxGCG1OldCollectionTime"]=Seconds
    ["JmxGCG1YoungCollectionCount"]=Count
    ["JmxGCG1YoungCollectionTime"]=Seconds
    ["JmxHeapMemoryUsageCommitted"]=Bytes
    ["JmxHeapMemoryUsageUsed"]=Bytes
    ["JmxNonHeapMemoryUsageCommitted"]=Bytes
    ["JmxNonHeapMemoryUsageUsed"]=Bytes
    ["JmxMetaspaceCommitted"]=Bytes
    ["JmxMetaspaceUsed"]=Bytes
    ["JmxConnectionPoolActiveConnections"]=Count
    ["JmxConnectionPoolIdleConnections"]=Count
    ["JmxConnectionPoolTotalConnections"]=Count
    ["JmxConnectionPoolThreadsAwaitingConnection"]=Count
)

DIMENSIONS_TASK=ServiceName=$SERVICE_NAME,TaskName=$TASK_NAME
DIMENSIONS_SEARVICE=ServiceName=$SERVICE_NAME

# Cloudwatchへメトリクスを送信(タスクレベル)
put_metics_data $DIMENSIONS_TASK

# Cloudwatchへメトリクスを送信(サービスレベル)
put_metics_data $DIMENSIONS_SEARVICE
