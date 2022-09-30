#!/bin/bash

helm uninstall intersystems
kubectl delete pvc --all

#kubectl delete pvc dbv-iris-0
#kubectl delete pvc iris-data-iris-vs2021-compute-0
#kubectl delete pvc iris-data-iris-vs2021-compute-1
#kubectl delete pvc iris-data-iris-vs2021-data-0-0
#kubectl delete pvc iris-data-iris-vs2021-data-0-1

kubectl delete secret dockerhub-secret
kubectl delete secret iris-key-secret
kubectl delete cm iris-cpf
kubectl delete cm iris-merge-cpf
kubectl delete cm iris-vs2021-compute
kubectl delete cm iris-vs2021-data
