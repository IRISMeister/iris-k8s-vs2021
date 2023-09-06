#!/bin/bash
source shell/envs.sh

# AKS用のRGを作成(なくても良いがaks関連だけを一括削除するのに便利)
az group create --name $aksrg --location "japaneast"

# AKSクラスタをデプロイ
# https://docs.microsoft.com/ja-jp/azure/aks/tutorial-kubernetes-deploy-cluster

az aks create \
 --resource-group $aksrg \
 --name myAKSCluster \
 --enable-managed-identity \
 --node-count 3 \
 --zones 1 2 3 \
 --generate-ssh-keys \
 --node-vm-size Standard_D4s_v3
 #--enable-addons monitoring 

# default = Standard_DS2_v2

# AKS クラスターの資格情報を取得
az aks get-credentials --overwrite-existing --resource-group $aksrg --name myAKSCluster

# az aks delete --name myAKSCluster --resource-group $aksrg