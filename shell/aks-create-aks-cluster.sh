#!/bin/bash
source shell/envs.sh

subnetid=$(az network vnet subnet list --resource-group $rg --vnet-name $vnet --query [].id --output tsv)

# AKS用のRGを作成(なくても良いが一括削除するのに便利)
az group create --name $aksrg --location "japaneast"

# AKSクラスタをデプロイ
# https://docs.microsoft.com/ja-jp/azure/aks/tutorial-kubernetes-deploy-cluster
az aks create \
 --resource-group $aksrg \
 --name "myAKSCluster" \
 --node-count 3 \
 --zones 1 2 3 \
 --service-principal $appid \
 --client-secret $password \
 --generate-ssh-keys \
 --network-plugin azure \
 --vnet-subnet-id $subnetid \
 --node-vm-size Standard_D4s_v3

# AKS クラスターの資格情報を取得
az aks get-credentials --overwrite-existing --resource-group $aksrg --name myAKSCluster
