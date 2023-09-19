# 事前準備
README.mdの[AKSクラスタの作成]まで完了している事

# Pod起動

```
kubectl run iris --image=containers.intersystems.com/intersystems/iris-community:2023.2.0.227.0 --
kubectl describe pod iris
kubectl logs iris
kubectl exec -ti iris -- bash
kubectl exec -ti iris -- iris session iris
kubectl delete pod iris
```

# StatefulSet起動

```
kubectl apply -f yaml/iris-ssd-sc-aks.yaml
kubectl apply -f yaml/iris-configmap-cpf.yaml
kubectl apply -f yaml/iris-statefulset.yml
kubectl exec -ti iris-0 -- iris session iris
kubectl get svc
  NAME      TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)           AGE
  my-iris   LoadBalancer   10.0.239.90   20.188.20.225   52773:30699/TCP   16s
```

管理ポータルへのアクセス

  http://EXTERNAL-IP:52773/csp/sys/%25CSP.Portal.Home.zen


ymlを修正し、適用することで、IRISインスタンスを増やすことができます。
```
replicas: 1->2
kubectl apply -f yaml/iris-statefulset.yml
kubectl delete -f yaml/iris-statefulset.yml
kubectl get pvc
kubectl delete pvc -l app=my-iris
```

# IKOによるバニラIRISのプロビジョン

## IKOのインストール

```
shell/prep-iris-cluster.sh
helm install intersystems chart/iris-operator --set nodeSelector.agentpool=nodepool1 --wait
```

> IRIS稼働ノードとの同居を避けるために、特定のノードプールにプロビジョンしています。

## IKOを使用したIRISのプロビジョン

```
$ kubectl apply -f yaml/iris-iko.yaml
$ kubectl get pod
NAME                                              READY   STATUS    RESTARTS   AGE
intersystems-iris-operator-amd-59fb7c65c7-h47xp   1/1     Running   0          35m
iris-vs2021-arbiter-0                             1/1     Running   0          3m3s
iris-vs2021-compute-0                             2/2     Running   0          113s
iris-vs2021-compute-1                             2/2     Running   0          82s
iris-vs2021-data-0-0                              2/2     Running   0          2m53s
iris-vs2021-data-0-1                              2/2     Running   0          2m22s

$ kubectl get svc
NAME                             TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                      AGE
intersystems-iris-operator-amd   ClusterIP      10.0.76.175   <none>           443/TCP                       35m
iris-svc                         ClusterIP      None          <none>           <none>                        3m
iris-vs2021                      LoadBalancer   10.0.36.165   52.253.120.229   1972:31723/TCP,80:30960/TCP   3m
kubernetes                       ClusterIP      10.0.0.1      <none>           443/TCP                       67m
```

管理ポータルへのアクセス


```
  serviceTemplate:
    spec:
      type: LoadBalancer
```
iris-iko.yamlにおいて上記の設定を行っています。その結果、LoadBalancerがプロビジョンされます。具体的には下記の設定になっており、現在プライマリになっているdataノードにアクセスします。

```
$  kubectl get svc iris-vs2021 -o yaml

  selector:
    intersystems.com/component: data
    intersystems.com/kind: IrisCluster
    intersystems.com/mirrorRole: primary
```

http://EXTERNAL-IP/csp/sys/%25CSP.Portal.Home.zen

ミラーモニタで、ミラー名がIRISMIRROR1であること、メンバIRIS-VS2021-DATA-0-0がプライマリであることを確認

> ECP環境において、直接dataノードに到達するようなサービスは不要かもしれません。

> computeノードの管理ポータルへのアクセスにはsidecarのWGWを使用します。

> (ラウンドロビンなど何某かのルールに基づいた)ロードバランサ経由でのcomputeノード群へのアクセスは別途、設定が必要になります。

## 操作

プライマリメンバ上でデータの更新を実行します。

```
kubectl exec -ti iris-vs2021-data-0-0 -- iris session iris -U IRISCLUSTER
IRISCLUSTER>f i=1:1:1000 s ^a(i)=i
IRISCLUSTER>h
```

バックアップメンバ上で上記の更新が反映されていることと、更新が失敗する事を確認します。

```
kubectl exec -ti iris-vs2021-data-0-1 -- iris session iris -U IRISCLUSTER
IRISCLUSTER>zw ^a
  ・
  ・
^a(998)=998
^a(999)=999
^a(1000)=1000
IRISCLUSTER>s ^a=1

S ^a=1
^
<PROTECT> ^a,/irissys/data/IRIS/mgr/iriscluster/
IRISCLUSTER>h
```

ECPクライアントからのアクセスを確認

```
kubectl exec -ti iris-vs2021-compute-0 -- iris session iris -U IRISCLUSTER
IRISCLUSTER>zw ^a
  ・
  ・
^a(998)=998
^a(999)=999
^a(1000)=1000
IRISCLUSTER>h
```

PODを強制停止して、ミラーをフェールオーバさせます。

```
kubectl delete pod iris-vs2021-data-0-0
```

この時点でBackupがPrimaryに切り替わります。

```
kubectl exec -ti iris-vs2021-data-0-1 -- iris session iris -U IRISCLUSTER
IRISCLUSTER>s ^x=1
IRISCLUSTER>h
```

削除したpodは自動回復し、やがてBackupメンバで起動します。

```
kubectl exec -ti iris-vs2021-data-0-0 -- iris session iris -U IRISCLUSTER
IRISCLUSTER>s ^x=2
S ^x=2
^
<PROTECT> ^x,/irissys/data/IRIS/mgr/iriscluster/
IRISCLUSTER>w ^x
1
IRISCLUSTER>h
```

## 各IRISインスタンスの管理ポータルへのアクセス方法

製品版なので、SideCarとして稼働させているWGW経由でアクセスします。

```
kubectl port-forward iris-vs2021-data-0-0 9999:80
あるいは
kubectl port-forward iris-vs2021-compute-0 9999:80
```

CSP管理画面は[http://localhost:9999/csp/bin/Systems/Module.cxw](http://localhost:9999/csp/bin/Systems/Module.cxw)

管理ポータルは、[http://localhost:9999/csp/sys/%25CSP.Portal.Home.zen](http://localhost:9999/csp/sys/%25CSP.Portal.Home.zen)


## IRISクラスタの削除およびPVの削除

```
kubectl delete -f yaml/iris-iko.yaml
kubectl delete pvc -l intersystems.com/name=iris-vs2021
```

# IKOによるユーザ作成のコンテナイメージのプロビジョン

イメージのビルドとテスト方法は[build.txt](build.txt)を参照。
    
もしpvが残っていたら削除します。

```
kubectl delete pvc -l intersystems.com/name=iris-vs2021
```

プロビジョン実行。
```
kubectl apply -f yaml/iris-iko-userimage.yaml
```

## SQLアクセス

(プライマリの)DATAノードにてテーブルにデータをロードし、COMPUTEノードから参照可能であることを確認します。

```
$ kubectl exec -ti iris-vs2021-data-0-0 -- iris session iris -U MYAPP
MYAPP>w ##class(MyApp.Utils).LoadCSV()
1
MYAPP>:sql
[SQL]MYAPP>>select * from person

PID     name    born
1       キアヌ・リーブス        1964
2       キャリー＝アン・モス    1967
    ・
    ・
6       ラナ・ウォシャウスキー  1965
7       ジョエル・シルバー      1952
---------------------------------------------------------------------------
[SQL]MYAPP>>q
```

バックアップのDATAノードでSELECT実行します。

```
$ kubectl exec -ti iris-vs2021-data-0-1 -- iris session iris -U MYAPP
MYAPP>:sql
同じSQLを発行して同一の出力となることを確認する。
```

ComputeノードでSELECT実行します。

```
$ kubectl exec -ti iris-vs2021-compute-0 -- iris session iris -U MYAPP
MYAPP>:sql
同じSQLを発行して同一の出力となることを確認する。
```

## RESTサービス

```
$ kubectl get svc
NAME                             TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                       AGE
iris-vs2021-webgateway           LoadBalancer   10.0.12.8      52.140.233.103   80:31108/TCP                  8m40s
```

iris-vs2021-webgatewayのEXTERNAL-IPを使用してRESTアクセスを行います。

```
$ extip=52.140.233.103
$ curl -s -u appuser:sys -X POST -H 'Content-type: application/json' -d '{a:1}' http://$extip/csp/myapp/test | jq
{
  "HostName": "iris-vs2021-compute-1",
  "UserName": "appuser",
  "Method": "Post",
  "TimeStamp": "09/11/2023 04:56:18"
}
$ curl -s -u appuser:sys http://$extip/csp/myapp/test
{
  "HostName": "iris-vs2021-compute-1",
  "UserName": "appuser",
  "Method": "Get",
  "TimeStamp": "09/11/2023 04:56:36",
  "Results": [
    {
      "TimeStamp": "09/11/2023 04:56:18"
    }
  ]
}
```

> Topology直下のwebgatewayは、GET先、POST先共にcompute-0, compute-1..., compute-nのラウンドロビンとなります。

## 各IRISインスタンスの管理ポータルへのアクセス方法

先ほどのIKO使用時と同じです。

## IRISクラスタの削除

```
kubectl delete -f yaml/iris-iko-userimage.yaml
kubectl delete pvc -l intersystems.com/name=iris-vs2021
```

# **** ここから先は、実験中です ****

# pythonを使用したロードバランス例

独自イメージとpython(http.server)を使用して、POSTはDATAに、GETはCOMPUTEに転送される環境をセットアップします。

1. イメージ名の変更

ご利用環境に合わせて[docker-compose.yml](docker-compose.yml)内のイメージ名を変更してください。

> 都合で、タグ名としてsimple-serverと使用していますが、普通はここにはバージョンを設定します。

```
  simple-server:
    image: dpmeister/irisdemo:simple-server
```

2. イメージをビルド、PUSHします。

```
$ cd python
$ docker compose build
$ docker compose push
```

3. K8Sにプロビジョンします。

```
$ kubectl apply -f yaml/simple-server.yaml
$ kubectl get svc
NAME                             TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                       AGE
simple-server                    LoadBalancer   10.0.131.22   20.222.220.118   80:32295/TCP                  23m
```

4. アクセス

simple-serverのEXTERNAL-IPを使用します。

```
$ extip=20.222.220.118
$ curl -s -u appuser:sys http://$extip/csp/myapp/test | jq
$ curl -s -u appuser:sys -X POST -H 'Content-type: application/json' -d '{a:1}' http://$extip/csp/myapp/test
```


# NGINXを使用したロードバランス例

(NGINX Community版使用につき、フェールオーバに難あり)

NGINXをリバースプロキシとして使用して、POSTはDATAに、GETはCOMPUTEに転送される環境をセットアップします。

## 実施手順

1. アクセス時にその応答から接続先がわかるように、WGW(サイドカー)用のApacheのindex.htmlの書き換えます。

```
kubectl exec -ti iris-vs2021-compute-0 -c webgateway -- bash -c 'echo "<html><body>compute-0</body></html>" > /var/www/html/index.html'
kubectl exec -ti iris-vs2021-compute-1 -c webgateway -- bash -c 'echo "<html><body>compute-1</body></html>" > /var/www/html/index.html'
kubectl exec -ti iris-vs2021-data-0-0 -c webgateway -- bash -c 'echo "<html><body>data-0-0</body></html>" > /var/www/html/index.html'
kubectl exec -ti iris-vs2021-data-0-1 -c webgateway -- bash -c 'echo "<html><body>data-0-1</body></html>" > /var/www/html/index.html'
```

2. nginxをプロビジョン

```
$ kubectl create cm nginx-config --from-file=conf/default.conf
$ kubectl apply -f yaml/nginx.yaml
$ kubectl get svc
NAME                             TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                       AGE
my-nginx                         LoadBalancer   10.0.187.162   52.253.120.187   80:31131/TCP                  4m41s
```

3. IRISの疎通確認

```
$ curl http://52.253.120.187/api/monitor/metrics
```

4. NGINX経由でアクセス実行

```
$ curl http://52.253.120.187/   <= my-nginxのEXTERNAL-IP 
<html><body>compute-0</body></html>
$ curl -X POST http://52.253.120.187/
<html><body>compute-1</body></html>
```

nginxのログ出力の確認を行います。

```
$ kubectl logs -f service/my-nginx

10.224.0.6 - - [06/Sep/2023:02:45:01 +0000] "GET / HTTP/1.1" 200 36 "-" "curl/7.81.0" "-"
10.224.0.5 - - [06/Sep/2023:02:45:13 +0000] "POST / HTTP/1.1" 200 36 "-" "curl/7.81.0" "-"
```

## 注意

NGINXは起動時に解決したIPをttlに無関係に使い続けるそうです。

https://qiita.com/kawakawaryuryu/items/af5dcb59aea1a10e4939

そのため、NGINXのbackendとして指定しているホストのIPが変わると、下記エラーが発生します。

```
2023/09/06 08:40:16 [error] 21#21: *1047 connect() failed (113: No route to host) while connecting to upstream, client: 10.244.1.1, server: nginx, request: "POST /csp/myapp/test HTTP/1.1", upstream: "http://10.244.1.21:80/csp/myapp/test", host: "20.27.13.103"
10.244.1.1 - appuser [06/Sep/2023:08:40:16 +0000] "POST /csp/myapp/test HTTP/1.1" 502 157 "-" "curl/7.81.0" "-"
```

プライマリのpodを2連続でdeleteするとこのような状況になります。(自動起動したprimaryのpodのIPが変わる)
そのため、フェールオーバ時には応答が止まってしまい下記のエラーが発生します。

```
$ curl -X POST http://20.27.13.103/csp/myapp/test -u appuser:sys
<html>
<head><title>504 Gateway Time-out</title></head>
<body>
<center><h1>504 Gateway Time-out</h1></center>
<hr><center>nginx/1.25.2</center>
</body>
</html>
```

また、ちゃんとLoadBalancerとして機能させるためには、HealthCheckを指定URL(/csp/bin/mirror_status.cxw)で能動的にチェックしてくれる機能を持つバランサが要ります。

```
root@my-nginx-66dc48b8dc-848f4:/# curl http://iris-vs2021-data-0-0.iris-svc.default.svc.cluster.local/csp/bin/mirror_status.cxw
SUCCESS
root@my-nginx-66dc48b8dc-848f4:/# curl http://iris-vs2021-data-0-1.iris-svc.default.svc.cluster.local/csp/bin/mirror_status.cxw
FAILED
```

# オプショナル

[こちら](optional.txt)では、監視ツールを導入しています。実行してもしなくても良い内容です。

実行すると、IKOを利用したプロビジョンを[Lens](https://k8slens.dev/)で表示するとこのようになります。
![lens1](lens1.png)
![lens2](lens2.png)

