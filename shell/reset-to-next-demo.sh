#!/bin/bash

kubectl delete -f yaml/iris-iko.yaml
kubectl delete -f yaml/iris-iko-userimage.yaml
kubectl delete pvc -l app=my-iris
kubectl delete pvc -l intersystems.com/name=iris-vs2021

kubectl delete secret dockerhub-secret
kubectl delete secret iris-key-secret
kubectl delete secret webgateway-secret

kubectl delete cm iris-cpf
kubectl delete cm iris-cpf-userimage
kubectl delete cm nginx-config

kubectl delete -f yaml/iris-ssd-sc-aks.yaml
