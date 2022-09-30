#!/bin/bash
source shell/envs.sh

# InterSystems Container RegistryからイメージをPullするためのsecret作成
# Community EditionではShard/ECPを構成できないため製品版を使用する。
# https://community.intersystems.com/post/introducing-intersystems-container-registry
kubectl create secret docker-registry dockerhub-secret \
--docker-server=https://containers.intersystems.com \
--docker-username=$iscuser --docker-password=$isccrpassword

# Config Mapとして、DATAノード用、COMPUTEノード用のIRIS構成ファイルを登録
kubectl create cm iris-cpf --from-file cpf/common.cpf --from-file cpf/data.cpf --from-file cpf/compute.cpf

# Secretとして、製品版用のライセンスキーを登録
kubectl create secret generic iris-key-secret --from-file=./iris.key
#($ kubectl describe secrets/iris-key-secret)

# データベースファイルを保存するためのstorage classを作成
# 既に作成済の場合、AlreadyExistsエラーが出る。
kubectl create -f yaml/iris-ssd-sc-aks.yaml