#!/bin/bash
source ../../utils.sh

kubectl delete -f ./service-ui.yaml
exit_if_error "Could not deploy service UI"
kubectl delete -f ./deployment-master.yaml
exit_if_error "Could not deploy master"
kubectl delete -f ./deployment-ui.yaml
exit_if_error "Could not deploy the ui"
kubectl delete -f ./deployment-workers.yaml
exit_if_error "Could not deploy workers"
kubectl delete -f ./iris-deployment.yaml
exit_if_error "Could not deploy workers"

kubectl delete pvc -l intersystems.com/name=htapirisdb
