source ../utils.sh
source ../../../shell/envs.sh

# For speedtest
az aks nodepool add --resource-group $aksrg --cluster-name $aksname --name ui --node-count 1 --node-vm-size Standard_DS2_v5 --labels speedtest/node-type=master-ui 
az aks nodepool add --resource-group $aksrg --cluster-name $aksname --name ingest --node-count 1 --node-vm-size Standard_DS2_v5 --labels speedtest/node-type=ingest 
az aks nodepool add --resource-group $aksrg --cluster-name $aksname --name query --node-count 1 --node-vm-size Standard_DS2_v5 --labels speedtest/node-type=query 

# speedtest用のcpf
kubectl create cm iris-cpf-speedtest --from-file ../cpf/data.cpf

# Speedtest用のPV
kubectl apply -f ./yaml/storage-class.yaml
# aksクラスタ作成時もしくはnodepool add時に--enable-ultra-ssd 指定が必要
#kubectl apply -f ./yaml/storage-class-ultra.yaml

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
