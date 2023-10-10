#!/bin/bash
source ../utils.sh

kubectl delete --wait -f ../yaml/service-ui.yaml --wait
exit_if_error "Could not deploy service UI"
kubectl delete --wait -f ../yaml/deployment-master.yaml --wait
exit_if_error "Could not deploy master"
kubectl delete --wait -f ../yaml/deployment-ui.yaml --wait
exit_if_error "Could not deploy the ui"
kubectl delete --wait -f ../yaml/deployment-workers.yaml --wait
exit_if_error "Could not deploy workers"

kubectl apply -f ../yaml/deployment-master.yaml
exit_if_error "Could not deploy master"
kubectl apply -f ../yaml/deployment-ui.yaml
exit_if_error "Could not deploy the ui"
sleep 10
kubectl apply -f ../yaml/deployment-workers.yaml
exit_if_error "Could not deploy workers"
kubectl apply -f ../yaml/service-ui.yaml
exit_if_error "Could not deploy service UI"
