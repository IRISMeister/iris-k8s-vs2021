#source ./envar.sh
source ../../utils.sh

kubectl apply -f ./storage-class.yaml
# aksクラスタ作成時に--enable-ultra-ssd 指定が必要
#kubectl apply -f ./storage-class-ultra.yaml

kubectl apply -f ./deployment-master.yaml
exit_if_error "Could not deploy master"
kubectl apply -f ./deployment-ui.yaml
exit_if_error "Could not deploy the ui"
# to prevent RESTART of workers
sleep 10
kubectl apply -f ./deployment-workers.yaml
exit_if_error "Could not deploy workers"
kubectl apply -f ./service-ui.yaml
exit_if_error "Could not deploy service UI"
sleep 12
kubectl apply -f ./iris-deployment.yaml
exit_if_error "Could not deploy iris"
