サービスを追加すると、PODの中からのアクセスにかかる時間が大幅に悪化する。

# AKS
$ shell/prep-iris-cluster.sh
$ kubectl apply -f ./simple-server.yaml
$ kubectl get pod
NAME                             READY   STATUS    RESTARTS   AGE
simple-server-64878c76f4-l8vl4   1/1     Running   0          37s

$ kubectl exec -ti simple-server-64878c76f4-l8vl4 -- bash
# curl -u appuser:sys -w "http_code: %{http_code}\ntime_namelookup: %{time_namelookup}\ntimeconnect: %{time_connect}\ntime_appconnect: %{time_appconnect}\ntime_pretransfer: %{time_pretransfer}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n" http://localhost:8080/csp/myapp/test
{"Result": {"Status": 1, "version": 1.0}}http_code: 200
time_namelookup: 0.000023
timeconnect: 0.000121
time_appconnect: 0.000000
time_pretransfer: 0.000164
time_starttransfer: 0.000614  <==早い
time_total: 0.000736


$ kubectl apply -f ./simple-server-svc.yaml
# curl -u appuser:sys -w "http_code: %{http_code}\ntime_namelookup: %{time_namelookup}\ntimeconnect: %{time_connect}\ntime_appconnect: %{time_appconnect}\ntime_pretransfer: %{time_pretransfer}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n" http://localhost:8080/csp/myapp/test
{"Result": {"Status": 1, "version": 1.0}}http_code: 200
time_namelookup: 0.000020
timeconnect: 0.000112
time_appconnect: 0.000000
time_pretransfer: 0.000157
time_starttransfer: 2.972902  <==かなり遅くなる
time_total: 2.972963
root@simple-server-64878c76f4-l8vl4:/usr/src/app#

time_starttransfer: Server側からResponseとして最初のbyteを受け取るまでの時間(TTFB, Time To First Byte)

typeがClusterIP,NodePortの場合は遅くならない。

# Local
docker compose up -d
GET
curl -u appuser:sys http://localhost:8888/csp/myapp/test
