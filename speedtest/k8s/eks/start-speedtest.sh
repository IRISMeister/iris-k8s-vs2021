source ../utils.sh
source ../../../shell/envs.sh

eksctl create cluster -f ./yaml/cluster-config.yaml

# 自動で行われる模様
# aws eks update-kubeconfig --region ap-northeast-1 --name speedtest-cluster


pushd ../../../
./shell/prep-iris-cluster.sh
helm install intersystems chart/iris-operator --wait
popd

# speedtest用のcpf
kubectl create cm iris-cpf-speedtest --from-file ../cpf/data.cpf

# (一時的な措置)azure用のSCを削除
kubectl delete -f ../../../yaml/iris-ssd-sc-aks.yaml
# Speedtest用のSC
kubectl apply -f ./yaml/storage-class.yaml


kubectl apply -f ../yaml/deployment-master.yaml
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
kubectl apply -f ./yaml/iris-deployment.yaml
exit_if_error "Could not deploy iris"

# メモ
# ノードグループ追加
# eksctl create nodegroup --config-file=./cluster-config.yaml --include={"ui","ingest","query"}
#
# EKSクラスタごと一括削除(スタックごと全て消える)
# 下記を実行しないと"1 pods are unevictable from node ip-192-168-28-134.ap-northeast-1.compute.internal"がループする
# kubectl delete pdb ebs-csi-controller -n kube-system
# eksctl delete cluster -f ./cluster-config.yaml
#     or
# eksctl delete cluster -f ./yaml/cluster-config.yaml --disable-nodegroup-eviction
#
