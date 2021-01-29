#!/bin/bash
#iris関連で使用するリソース用のリソースグループ
export rg=iris-rg
#VNETの名前
export vnet=iris-vnet
#AKS関連で使用するリソース用のリソースグループ
export aksrg=iris-aks-rg
#AKSで使用するサブネット
export subnet=myAKSSubnet

export password=_azure_password_here_
export appid=_azure_appid_here_

#ICR用のpasswordハッシュ
export iscuser=_intersyetems_container_repo_username_here_
export isccrpassword=_intersyetems_container_repo_token_here_
