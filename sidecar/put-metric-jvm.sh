#!/bin/bash

echo "##### start put-metric-jvm.sh #####"

function put_metics_data() {
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxGCG1OldCollectionCount --value $JMX_V1 --unit Count
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxGCG1OldCollectionTime --value $JMX_V2 --unit Seconds
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxGCG1YoungCollectionCount --value $JMX_V3 --unit Count
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxGCG1YoungCollectionTime --value $JMX_V4 --unit Seconds
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxHeapMemoryUsageCommitted --value $JMX_V5 --unit Bytes
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxHeapMemoryUsageUsed --value $JMX_V7 --unit Bytes
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxNonHeapMemoryUsageCommitted --value $JMX_V8 --unit Bytes
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxNonHeapMemoryUsageUsed --value $JMX_V10 --unit Bytes
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxMetaspaceCommitted --value $JMX_V20 --unit Bytes
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxMetaspaceUsed --value $JMX_V22 --unit Bytes
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxConnectionPoolActiveConnections --value $JMX_V29 --unit Count
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxConnectionPoolIdleConnections --value $JMX_V30 --unit Count
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxConnectionPoolTotalConnections --value $JMX_V31 --unit Count
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxConnectionPoolThreadsAwaitingConnection --value $JMX_V32 --unit Count
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

# JMXクライアントツールでJVMのメトリクスを取得する
JMX_V1=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:name=G1 Old Generation,type=GarbageCollector" CollectionCount 2>&1 | cut -d' ' -f6`
JMX_V2=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:name=G1 Old Generation,type=GarbageCollector" CollectionTime 2>&1 | cut -d' ' -f6`
JMX_V3=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:name=G1 Young Generation,type=GarbageCollector" CollectionCount 2>&1 | cut -d' ' -f6`
JMX_V4=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:name=G1 Young Generation,type=GarbageCollector" CollectionTime 2>&1 | cut -d' ' -f6`
JMX_V5=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:type=Memory" HeapMemoryUsage  2>&1 | grep committed | cut -d' ' -f2`
JMX_V7=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:type=Memory" HeapMemoryUsage  2>&1 | grep used | cut -d' ' -f2`
JMX_V8=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:type=Memory" NonHeapMemoryUsage  2>&1 | grep committed | cut -d' ' -f2`
JMX_V10=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:type=Memory" NonHeapMemoryUsage  2>&1 | grep used | cut -d' ' -f2`
JMX_V20=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:name=Metaspace,type=MemoryPool" Usage 2>&1 | grep committed | cut -d' ' -f2`
JMX_V22=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:name=Metaspace,type=MemoryPool" Usage 2>&1 | grep used | cut -d' ' -f2`
JMX_V29=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "com.zaxxer.hikari:type=Pool (HikariPool-1)" ActiveConnections 2>&1 | cut -d' ' -f6`
JMX_V30=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "com.zaxxer.hikari:type=Pool (HikariPool-1)" IdleConnections 2>&1 | cut -d' ' -f6`
JMX_V31=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "com.zaxxer.hikari:type=Pool (HikariPool-1)" TotalConnections 2>&1 | cut -d' ' -f6`
JMX_V32=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "com.zaxxer.hikari:type=Pool (HikariPool-1)" ThreadsAwaitingConnection 2>&1 | cut -d' ' -f6`

DIMENSIONS_TASK=ServiceName=$SERVICE_NAME,TaskName=$TASK_NAME
DIMENSIONS_SEARVICE=ServiceName=$SERVICE_NAME

# Cloudwatchへメトリクスを送信(タスクレベル)
put_metics_data $DIMENSIONS_TASK

# Cloudwatchへメトリクスを送信(サービスレベル)
put_metics_data $DIMENSIONS_SEARVICE
