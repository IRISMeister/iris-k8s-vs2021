# speedtest

## 目的

[Hybrid Transactional-Analytical Processing (HTAP) Demo](https://github.com/intersystems-community/irisdemo-demo-htap) をAKS環境で動作させる事。

目的はアプリケーション動作環境の例示です。大幅に使用リソース(CPU,Memory,Disk性能等など)を減らしているため、ベンチマーク、性能測定のためには不向きです。

## 事前準備

事前作業(IKO使用時)、AKSクラスタ作成、shell/prep-iris-cluster.shの実行まで完了していること。

下記のような状態になっているはずです。

```
$ kubectl get node
NAME                                STATUS   ROLES   AGE     VERSION
aks-ingest-23936547-vmss000000      Ready    agent   5m39s   v1.26.6
aks-iris-13600519-vmss000000        Ready    agent   9m38s   v1.26.6
aks-iris-13600519-vmss000001        Ready    agent   9m38s   v1.26.6
aks-iris-13600519-vmss000002        Ready    agent   9m22s   v1.26.6
aks-nodepool1-29403018-vmss000000   Ready    agent   13m     v1.26.6
aks-query-40989049-vmss000000       Ready    agent   79s     v1.26.6
aks-ui-41381550-vmss000000          Ready    agent   7m9s    v1.26.6
$ kubectl get pod
NAME                                              READY   STATUS    RESTARTS   AGE
intersystems-iris-operator-amd-5c89c8fccc-bgqwx   1/1     Running   0          57s

$ kubectl get cm
NAME                 DATA   AGE
iris-cpf             4      2m10s
iris-cpf-userimage   4      2m10s
kube-root-ca.crt     1      14m
nginx-config         1      2m9s

$ kubectl get pvc
No resources found in default namespace.
```

## 実行

```
cd irisdemo/Kubernetes/Deployments/cluster1
./start-speedtest.sh
```

下記操作で、U/Iにアクセスできます。現状、安全性のために公開IPは割り当てていません。

```
$ kubectl port-forward svc/ui 4200:4200
```
Open http://localhost:4200/


下記操作で、管理ポータルにアクセスできます。現状、安全性のために公開IPは割り当てていません。

```
$ kubectl port-forward pod/htapirisdb-data-0-0 8888:80
```
Open http://localhost:8888/csp/sys/%25CSP.Portal.Home.zen

## アプリケーション再起動

IRIS以外を再起動(リセット)します。予期せぬエラー発生時に使用します。

```
$ ./bounce-speedtest.sh
```

## 停止(削除)

```
# ./delete-speedtest.sh
```
