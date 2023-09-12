#!/bin/bash
source ../../utils.sh

kubectl delete --wait -f ./service-ui.yaml
exit_if_error "Could not deploy service UI"
kubectl delete --wait -f ./deployment-master.yaml
exit_if_error "Could not deploy master"
kubectl delete --wait -f ./deployment-ui.yaml
exit_if_error "Could not deploy the ui"
kubectl delete --wait -f ./deployment-workers.yaml
exit_if_error "Could not deploy workers"

kubectl apply -f ./deployment-master.yaml
exit_if_error "Could not deploy master"
kubectl apply -f ./deployment-ui.yaml
exit_if_error "Could not deploy the ui"
sleep 10
kubectl apply -f ./deployment-workers.yaml
exit_if_error "Could not deploy workers"
kubectl apply -f ./service-ui.yaml
exit_if_error "Could not deploy service UI"
