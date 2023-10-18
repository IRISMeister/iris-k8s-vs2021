#!/bin/bash
source shell/envs.sh

# Docker Desktop(Windows)をインストールすると、config.jsonに下記のエントリが出来て、pullが認証エラーになるという障害あり。
# "credsStore": "desktop.exe"
# 対処療法は、"_credsStore": "desktop.exe"に書き換えて、docker loginしなおす。--> "credsStore"が消える。
kubectl create secret generic dockerhub-secret \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson

# DATAノード、COMPUTEノード用のIRIS構成ファイルおよびWGWの構成ファイルを登録
# 独立したwebgateway使用中止
#kubectl create cm iris-cpf --from-file cpf/CSP-merge.ini --from-file cpf/common.cpf --from-file cpf/data.cpf --from-file cpf/compute.cpf
kubectl create cm iris-cpf --from-file cpf/common.cpf --from-file cpf/data.cpf --from-file cpf/compute.cpf

# ユーザ作成イメージ用を使用する場合に使用
# 独立したwebgateway使用中止
#kubectl create cm iris-cpf-userimage --from-file cpf/CSP-merge.ini --from-file cpf/common.cpf --from-file cpf/userimage/data.cpf --from-file cpf/userimage/compute.cpf
kubectl create cm iris-cpf-userimage --from-file cpf/common.cpf --from-file cpf/userimage/data.cpf --from-file cpf/userimage/compute.cpf

# For sidecar WGWs
# ドキュメント誤り。Prefixは[[[ではなく]]]
kubectl create secret generic webgateway-secret --from-literal=username=CSPSystem --from-literal=password=]]]U1lT

# Secretとして、製品版用のライセンスキーを登録
kubectl create secret generic iris-key-secret --from-file=./iris.key
#($ kubectl describe secrets/iris-key-secret)

# ロードバランス用のnginx(テスト設定)の構成ファイル
kubectl create cm nginx-config --from-file=conf/default.conf

# データベースファイルを保存するためのstorage classを作成
# 既に作成済の場合、AlreadyExistsエラーが出る。
kubectl create -f yaml/iris-ssd-sc-aks.yaml
