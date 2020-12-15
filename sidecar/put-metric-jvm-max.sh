#!/bin/bash

echo "##### start put-metric-jvm-max.sh #####"

function put_metics_data() {
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxHeapMemoryUsageMax --value $JMX_V6 --unit Bytes
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxNonHeapMemoryUsageMax --value $JMX_V9 --unit Bytes
    aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace Jmx --metric-name JmxMetaspaceMax --value $JMX_V21 --unit Bytes
}

# ECSメタデータエンドポイントのURLを変数にセットする
TASK_META_ENDPOINT=${ECS_CONTAINER_METADATA_URI_V4}/task

# メタデータのJSONを変数にセットする
METADATA_JSON=`curl -s $META_ENDPOINT`

TASK_ARN=`echo $TASK_META_JSON | jq -r .TaskARN`
TASK_NAME=`echo $TASK_ARN | tr '/' '\n' | tail -1`
# サービスまたはタスク定義からタスク起動時にタグを伝播させるのが前提
# メタデータから取得出来ない情報をタグから取得する
SERVICE_NAME=`aws ecs list-tags-for-resource --resource-arn $TASK_ARN | jq '.tags[] | select(.key == "aws:ecs:serviceName") | .value'`
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
JMX_PORT=10048
JMXCLIENT_PATH=/metric/cmdline-jmxclient-0.10.3.jar

# JMXクライアントツールでJVMのメトリクスを取得する
JMX_V6=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:type=Memory" HeapMemoryUsage 2>&1 | grep max | cut -d' ' -f2`
JMX_V9=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:type=Memory" NonHeapMemoryUsage 2>&1 | grep max | cut -d' ' -f2`
JMX_V21=`java -jar $JMXCLIENT_PATH - localhost:$JMX_PORT "java.lang:name=Metaspace,type=MemoryPool" Usage 2>&1 | grep max | cut -d' ' -f2`

DIMENSIONS_TASK=ServiceName=$SERVICE_NAME,TaskName=$TASK_NAME
DIMENSIONS_SEARVICE=ServiceName=$SERVICE_NAME

# Cloudwatchへメトリクスを送信(タスクレベル)
put_metics_data $DIMENSIONS_TASK

# Cloudwatchへメトリクスを送信(サービスレベル)
put_metics_data $DIMENSIONS_SEARVICE
