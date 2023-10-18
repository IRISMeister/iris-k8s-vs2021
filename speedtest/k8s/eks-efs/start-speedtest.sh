source ../utils.sh
source ../../../shell/envs.sh

eksctl create cluster -f ../eks/yaml/cluster-config.yaml

# 自動で行われる模様
# aws eks update-kubeconfig --region ap-northeast-1 --name speedtest-cluster

pushd ../../../
./shell/prep-iris-cluster.sh
popd

# speedtest用のcpf
kubectl create cm iris-cpf-speedtest --from-file ../cpf/data.cpf

# EFSを作成し、EFS用のCSIを使用したStorageClassを作成する。
# https://repost.aws/ja/knowledge-center/eks-persistent-storage
rm ./param.txt
export vpcid=`aws eks describe-cluster --name speedtest-cluster --query "cluster.resourcesVpcConfig.vpcId" | jq -r`
export vpccidr=`aws ec2 describe-vpcs --vpc-ids $vpcid --query "Vpcs[].CidrBlock" --output text`
export sgid=`aws ec2 create-security-group --description efs-test-sg --group-name efs-sg --vpc-id $vpcid --output text`
aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port 2049 --cidr $vpccidr
export filesystemid=`aws efs create-file-system --creation-token eks-efs | jq -r '.FileSystemId'`
echo $vpcid >> param.txt
echo $vpccidr >> param.txt
echo $sgid >> param.txt
echo $filesystemid >> param.txt
# subnet idの取得。ここではクラスタ内の全subnetを取得している(結果、全ノードからnfsマウント出来る)が
# 本来は分散ストレージを使用する可能性のあるsubnet(つまりはIRISを稼働させたいノードが属するサブネット)だけで良い。
aws eks describe-cluster --name speedtest-cluster --query cluster.resourcesVpcConfig.subnetIds > subnets.json
./create-mount-target.sh

# fileSystemIdを$filesystemidに書き換える必要あり。
cat ./yaml/sc.yaml.template | sed "s/{{fileSystemId}}/$filesystemid/g" > ./yaml/sc2.yaml
kubectl apply -f ./sc.yaml


# スクリプトを共有している関係で出来上がっている不要なAzure用のSC(当然EKSでは機能しない)を削除
kubectl delete -f ../../../yaml/iris-ssd-sc-aks.yaml
# Speedtest用のSC
kubectl apply -f ../eks/yaml/storage-class.yaml

# 以下の差異があるため、deployment-master.yamlはEFS専用(正確にはミラー未使用時専用)を用意した。
# ミラー使用時(IRISCLUSTER)とはネームスペースが異なる(USER)
# EFSではDATABASE_SIZE_IN_GBが15GBだとタイムアウトするため1GBに修正。
kubectl apply -f ./yaml/deployment-master.yaml
exit_if_error "Could not deploy master"
kubectl apply -f ../yaml/deployment-ui.yaml
exit_if_error "Could not deploy the ui"
# to prevent RESTART of workers
sleep 10
kubectl apply -f ../yaml/deployment-workers.yaml
exit_if_error "Could not deploy workers"
kubectl apply -f ../yaml/service-ui.yaml
exit_if_error "Could not deploy service UI"
sleep 12
# pv動的プロビジョニング使用。
kubectl apply -f ./yaml/iris-statefulset.yaml
exit_if_error "Could not deploy iris"

# see /home/irismeister/git/iris-k8s-vs2021/speedtest/README.md

# 削除手順
# ../eks/delete-speedtest.sh
# kubectl delete -f ./yaml/iris-statefulset.yaml
# kubectl delete pvc --all
# kubectl delete pdb ebs-csi-controller -n kube-system
#   EFS削除。CLI化可能？
# aws ec2 delete-security-group --group-id $sgid
# eksctl delete cluster -f ../eks/yaml/cluster-config.yaml
# CFがDELETEされていることを確認すること。失敗時は、マニュアルで関連するVPCなど使用したリソースを削除したうえで、CFをマニュアルで削除すること。
