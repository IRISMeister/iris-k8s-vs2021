#!/bin/bash
source shell/envs.sh

# AKSで使用するVNET用のリソースグループ作成
az group create --name $rg --location "japaneast"

# 同サブネット作成
az network vnet create --name $vnet --resource-group $rg --subnet-name default

# VNETのリソースID取得
irisvnet=$(az network vnet show --resource-group $rg --name $vnet --query id -o tsv)

# サーバーノードをVNETに追加する権限付与
az role assignment create --assignee $appid --scope $irisvnet --role Contributor

# AKS用サブネット作成
# https://docs.microsoft.com/ja-jp/azure/aks/configure-kubenet
az network vnet create --resource-group $rg --name $vnet --address-prefixes 192.168.0.0/16 --subnet-name $subnet --subnet-prefix 192.168.1.0/24

# AKS用サブネットのリソースID確認
az network vnet subnet list --resource-group $rg --vnet-name $vnet --query [].id --output tsv

