#!/bin/bash
source shell/envs.sh

# AKS用のRGを作成(なくても良いがaks関連だけを一括削除するのに便利)
az group create --name $aksrg --location "japaneast"

# AKSクラスタをデプロイ
# https://docs.microsoft.com/ja-jp/azure/aks/tutorial-kubernetes-deploy-cluster

az aks create -g $aksrg --name $aksname --node-count 1 --generate-ssh-keys --nodepool-taints CriticalAddonsOnly=true:NoSchedule --node-vm-size Standard_DS2_v2

# AKS クラスターの資格情報を取得
az aks get-credentials --overwrite-existing --resource-group $aksrg --name $aksname

# For IRIS cluster
az aks nodepool add --resource-group $aksrg --cluster-name $aksname --mode user --name iris --node-count 3 --zones 1 2 3 --node-vm-size Standard_D4s_v3 --labels speedtest/node-type=iris
# UltraSSD_LRS使用時
#az aks nodepool add --resource-group $aksrg --cluster-name $aksname --mode user --name irisultra --node-count 3 --zones 1 2 3 --enable-ultra-ssd --node-vm-size Standard_D4s_v3 --labels speedtest/node-type=iris

# For speedtest
az aks nodepool add --resource-group $aksrg --cluster-name $aksname --name ui --node-count 1 --labels speedtest/node-type=master-ui 
az aks nodepool add --resource-group $aksrg --cluster-name $aksname --name ingest --node-count 1 --labels speedtest/node-type=ingest 
az aks nodepool add --resource-group $aksrg --cluster-name $aksname --name query --node-count 1 --labels speedtest/node-type=query 

# az aks delete --name $aksname --resource-group $aksrg