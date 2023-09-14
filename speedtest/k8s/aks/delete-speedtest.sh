#!/bin/bash
source ../utils.sh

kubectl delete -f ../yaml/service-ui.yaml
exit_if_error "Could not deploy service UI"
kubectl delete -f ../yaml/deployment-master.yaml
exit_if_error "Could not deploy master"
kubectl delete -f ../yaml/deployment-ui.yaml
exit_if_error "Could not deploy the ui"
kubectl delete -f ../yaml/deployment-workers.yaml
exit_if_error "Could not deploy workers"
kubectl delete -f ./yaml/iris-deployment.yaml
exit_if_error "Could not deploy workers"

kubectl delete pvc -l intersystems.com/name=htapirisdb
