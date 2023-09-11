# Local(docker community版)で実行する方法
$ docker compose up -d
$ curl -u appuser:sys http://localhost:8888/csp/myapp/test


$ shell/prep-iris-cluster.sh
$ kubectl apply -f ./simple-server.yaml 
$ kubectl get pod
NAME                             READY   STATUS    RESTARTS   AGE
simple-server-64878c76f4-l8vl4   1/1     Running   0          37s

$ kubectl exec -ti simple-server-64878c76f4-l8vl4 -- bash
# curl -u appuser:sys -w "http_code: %{http_code}\ntime_namelookup: %{time_namelookup}\ntimeconnect: %{time_connect}\ntime_appconnect: %{time_appconnect}\ntime_pretransfer: %{time_pretransfer}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n" http://localhost/csp/myapp/test
{"Result": {"Status": 1, "version": 1.0}}http_code: 200
time_namelookup: 0.000023
timeconnect: 0.000121
time_appconnect: 0.000000
time_pretransfer: 0.000164
time_starttransfer: 0.000614 
time_total: 0.000736

time_starttransfer: Server側からResponseとして最初のbyteを受け取るまでの時間(TTFB, Time To First Byte)

root@simple-server-64878c76f4-l8vl4:/usr/src/app# netstat
Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 simple-server-648:38828 151.101.110.132:http    TIME_WAIT
tcp        0      0 simple-server-648:44736 151.101.110.132:http    TIME_WAIT
tcp        0      0 simple-server-6487:http aks-nodepool1-391:28211 ESTABLISHED <= 何もしなくてもhttpに接続されている
tcp        0      0 simple-server-6487:http 10.244.2.1:36151        ESTABLISHED <=
tcp        0      0 simple-server-6487:http aks-nodepool1-391:12281 ESTABLISHED <=
tcp        0      0 localhost:http          localhost:59662         TIME_WAIT
Active UNIX domain sockets (w/o servers)
Proto RefCnt Flags       Type       State         I-Node   Path

root@simple-server-64878c76f4-l8vl4:/usr/src/app# netstat -l
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        2      0 0.0.0.0:http            0.0.0.0:*               LISTEN  <== そのためRecv-Qが待ちになっている
Active UNIX domain sockets (only servers)
Proto RefCnt Flags       Type       State         I-Node   Path

simple-server.pyをマルチスレッド化することで解決。
