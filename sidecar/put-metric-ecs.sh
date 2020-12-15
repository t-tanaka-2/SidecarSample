#!/bin/bash
echo "##### start put-metric-ecs.sh #####"

function put_metics_data() {
  aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace ECS --metric-name ContainerCPUUtilization --value $CPU_USAGE_RATIO --unit Percent
  aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace ECS --metric-name ContainerMemoryUsageUsed --value $MEMORY_USAGE --unit Bytes
  aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace ECS --metric-name ContainerMemoryUsageMax --value $MEMORY_LIMIT --unit Bytes
  aws cloudwatch put-metric-data --dimensions $1 --timestamp $TIMESTAMP --namespace ECS --metric-name ContainerMemoryUtilization --value $MEMORY_USAGE_RATIO --unit Percent
}

# ECSメタデータエンドポイントのURLを変数にセットする
META_ENDPOINT=${ECS_CONTAINER_METADATA_URI_V4}
TASK_META_ENDPOINT=${ECS_CONTAINER_METADATA_URI_V4}/task
TASK_STATS_ENDPOINT=${ECS_CONTAINER_METADATA_URI_V4}/task/stats

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# メタデータのJSONを変数にセットする
METADATA_JSON=`curl -s $META_ENDPOINT`
TASK_META_JSON=`curl -s $TASK_META_ENDPOINT`
TASK_STATS_JSON=`curl -s $TASK_STATS_ENDPOINT`

TASK_ARN=`echo $TASK_META_JSON | jq -r .TaskARN`
TASK_NAME=`echo $TASK_ARN | tr '/' '\n' | tail -1`
# サービスまたはタスク定義からタスク起動時にタグを伝播させるのが前提
# メタデータから取得出来ない情報をタグから取得する
APP_CONTAINER_NAME=`aws ecs list-tags-for-resource --resource-arn $TASK_ARN | jq '.tags[] | select(.key == "Main Container") | .value'`
SERVICE_NAME=`aws ecs list-tags-for-resource --resource-arn $TASK_ARN | jq '.tags[] | select(.key == "aws:ecs:serviceName") | .value'`
APP_CONTAINER_ID=`echo $TASK_META_JSON | jq ".Containers[] | select(.Name | test($APP_CONTAINER_NAME) ) | .DockerId"`

# アプリコンテナのCPUメトリクスを取得
SYSTEM_CPU_USAGE=`echo $TASK_STATS_JSON | jq ".$APP_CONTAINER_ID | .cpu_stats.system_cpu_usage"`
TOTAL_CPU_USAGE=`echo $TASK_STATS_JSON | jq ".$APP_CONTAINER_ID | .cpu_stats.cpu_usage.total_usage"`
PRE_SYSTEM_CPU_USAGE=`echo $TASK_STATS_JSON | jq ".$APP_CONTAINER_ID | .precpu_stats.system_cpu_usage"`
PRE_TOTAL_CPU_USAGE=`echo $TASK_STATS_JSON | jq ".$APP_CONTAINER_ID | .precpu_stats.cpu_usage.total_usage"`
ONLINE_CPUS=`echo $TASK_STATS_JSON | jq ".$APP_CONTAINER_ID | .cpu_stats.online_cpus"`
CPU_USAGE_RATIO=`python -c "print(($TOTAL_CPU_USAGE-$PRE_TOTAL_CPU_USAGE)*1.0/($SYSTEM_CPU_USAGE-$PRE_SYSTEM_CPU_USAGE)*$ONLINE_CPUS*100)"`
  
# アプリコンテナのメモリメトリクスを取得
MEMORY_LIMIT=`echo $TASK_STATS_JSON | jq ".$APP_CONTAINER_ID | .memory_stats.limit"`
MEMORY_USAGE=`echo $TASK_STATS_JSON | jq ".$APP_CONTAINER_ID | .memory_stats.usage"`
MEMORY_USAGE_RATIO=`python -c "print($MEMORY_USAGE*1.0/$MEMORY_LIMIT*100)"`

DIMENSIONS_TASK=ServiceName=$SERVICE_NAME,TaskName=$TASK_NAME
DIMENSIONS_SEARVICE=ServiceName=$SERVICE_NAME

# Cloudwatchへメトリクスを送信(タスクレベル)
put_metics_data $DIMENSIONS_TASK

# Cloudwatchへメトリクスを送信(サービスレベル)
put_metics_data $DIMENSIONS_SEARVICE
