#!/bin/bash

kubectl delete pvc -l app=my-iris
kubectl delete pvc -l intersystems.com/name=iris-vs2021

kubectl delete secret dockerhub-secret
kubectl delete secret dockerhub-secret-userimage
kubectl delete secret iris-key-secret

kubectl delete cm iris-cpf
kubectl delete cm iris-cpf-userimage
kubectl delete cm iris-merge-cpf
kubectl delete cm iris-vs2021-compute
kubectl delete cm iris-vs2021-data-0

kubectl delete -f yaml/iris-ssd-sc-aks.yaml
