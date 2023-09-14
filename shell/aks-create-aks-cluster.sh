#!/bin/bash
source shell/envs.sh

# AKS用のRGを作成(なくても良いがaks関連だけを一括削除するのに便利)
az group create --name $aksrg --location "japaneast"

# AKSクラスタをデプロイ

# IKOをここ(nodepool1)で動かしたいので、--nodepool-taints CriticalAddonsOnly=true:NoScheduleを除去
az aks create -g $aksrg --name $aksname --node-count 1 --generate-ssh-keys --node-vm-size Standard_DS2_v2

# AKS クラスターの資格情報を取得
az aks get-credentials --overwrite-existing --resource-group $aksrg --name $aksname

# For IRIS cluster
az aks nodepool add --resource-group $aksrg --cluster-name $aksname --mode user --name iris --node-count 2 --zones 1 2 --node-vm-size Standard_D4s_v3 --labels speedtest/node-type=iris
az aks nodepool add --resource-group $aksrg --cluster-name $aksname --mode user --name arbiter --node-count 1 --zones 3 --node-vm-size Standard_DS2_v2 --labels speedtest/node-type=iris-arbiter
# UltraSSD_LRS使用時
#az aks nodepool add --resource-group $aksrg --cluster-name $aksname --mode user --name irisultra --node-count 2 --zones 1 2 --enable-ultra-ssd --node-vm-size Standard_D4s_v3 --labels speedtest/node-type=iris
#az aks nodepool add --resource-group $aksrg --cluster-name $aksname --mode user --name arbiter --node-count 1 --zones 3 --node-vm-size Standard_DS2_v2 --labels speedtest/node-type=iris-arbiter
