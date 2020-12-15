# JVM、ECSコンテナのメトリクスを収集するサイドカー

## ビルド・デプロイ手順
・AWS環境へdocker login
https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/Registries.html#registry_auth

・docker build
```
docker build . -t タグ名
```

・docker push
https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/docker-push-ecr-image.html
