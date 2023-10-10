eksctl create cluster -f ./cluster-config.yaml

# 自動で行われる模様
# aws eks update-kubeconfig --region ap-northeast-1 --name speedtest-cluster


pushd ../../
./shell/prep-iris-cluster.sh
helm install intersystems chart/iris-operator --wait
popd

# (一時的な措置)azure用のSCを削除
kubectl delete -f ../../yaml/iris-ssd-sc-aks.yaml
# Speedtest用のSC
kubectl apply -f ./storage-class.yaml

kubectl apply -f ./iris-iko.yaml

#クラスタごと削除してもpv(EBSボリューム)が残ることがあったので注意。
# kubectl delete pdb ebs-csi-controller -n kube-system
# eksctl delete cluster -f ./cluster-config.yaml
