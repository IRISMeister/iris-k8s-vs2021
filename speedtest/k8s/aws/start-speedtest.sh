#source ./envar.sh
source ../utils.sh
#source ../../shell/envs.sh

eksctl create cluster -f ./cluster-config.yaml

# クラスタ作成後のノードプール追加
# eksctl create nodegroup --config-file=./cluster-config.yaml --include=arbiter

pushd ../../../
./shell/prep-iris-cluster.sh
helm install intersystems chart/iris-operator --wait
popd

# speedtest用のcpf
kubectl create cm iris-cpf-speedtest --from-file ../cpf/data.cpf

# Speedtest用のPV
# azure用のSCを削除
kubectl delete sc iris-ssd-storageclass
kubectl apply -f ./yaml/storage-class.yaml

# eksctl delete cluster -f ./cluster-config.yaml