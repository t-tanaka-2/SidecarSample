# JVMのメトリクスを監視するサイドカーのサンプル

##  プロジェクト構成
| プロジェクト名 | 内容物 |
| :--- | :--- |
| sidecar | サイドカーコンテナのコード群 | 
| sidecardemo | サイドカーがJVM監視を監視するサンプルのJavaアプリ |

## ECSのタスク定義について
* DBコネクション周りのメトリクスを取るためにRDSを立てたくなかったので、同一タスクの中でPostgresのDBも立てています
* DBコンテナの環境変数に下記を設定すれば最低限DB接続はされます
	* キー： POSTGRES_PASSWORD
	* 値　： mysecretpassword
	* 設定については→参照 https://hub.docker.com/_/postgres

## 詳細
QiitaのURLを後で貼る
