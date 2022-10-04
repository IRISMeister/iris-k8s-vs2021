# 実行に際して
StatefulSetを使用したデプロイは、Community版を使用しますので、どなたでも実行可能です。  
InterSystems Kubernetes Operatorは製品版IRISを使用するため、有効なWRCアカウントが必要となります。

# 事前作業
## 事前作業

事前作業を実施する環境として、Ubuntu20.04をご用意ください。
0. Git クローン
    ```bash
    $ git clone https://github.com/IRISMeister/iris-k8s-vs2021.git
    $ cd iris-k8s-vs2021
    ```

1. az cli, kubectlのインストール  

    az cli
    ```bash
    $ curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    ```
    kubectl
    ```bash
    $ sudo az aks install-cli
    ```

2. サービスプリンシパル作成  
アプリケーション実行用のID(aks用のサービスプリンシパル)を作成します。出力値は取り扱い注意です。

    ```bash
    $ az login   (ブラウザ経由での認証を実行)
    $ az ad sp create-for-rbac --skip-assignment
    {
    "appId": "xxxxxxxxxx",
    "displayName": "azure-cli-2020-10-26-03-51-23",
    "name": "http://azure-cli-2020-10-26-03-51-23",
    "password": "yyyyyyyyyy",
    "tenant": "zzzzzzzzzz"
    }
    ```

3. envs.shの編集  
 利用者に関するセンシティブな情報は全てshell/envs.shに格納します。以後、このファイルは取り扱い注意です(間違ってpublicなレポジトリにpushしないよう)。

    (事前作業 2.サービスプリンシパル作成)で取得したappId,passwordを下記と置き換えてください。

    ```bash
    cp envs.sh.template envs.sh
    vi envs.sh
    export appid=_azure_appid_here_
    export password=_azure_password_here_
    ```

4. IRISパスワードの設定
IRIS用のPassword Hashの作成及び定義への反映を行います。  
公式ドキュメント  
https://docs.intersystems.com/iris20201/csp/docbookj/Doc.View.cls?KEY=ADOCK#ADOCK_iris_images_password_auth

    ```bash
    $ docker run --rm -it containers.intersystems.com/intersystems/passwordhash:1.1
    Enter password:
    Enter password again:
    PasswordHash=34e80d2f1ad5135679b3a57a9c4b1611a8a8995e0849ebe954ac1c16ad253d0274296985fea058a8aaf2a149b88082595e6374b3c2f7d5f0774f05e4311ba52d,124e81ee6bf17fcaf0dfb38a4f8a7f46e9e4b0c8c9a40864bb189d4d200b161b1451874efcbed63b801cbab592434b93037e90810d96e4ee123ac03b756779e9,10000,SHA512

    ```
    PasswordHash=xxxxxの箇所を、[iris-configmap-cpf.yaml](yaml/iris-configmap-cpf.yaml)に上書きします。  
    初期設定されているハッシュ値はパスワードSYSを指定して作成したものです。
    
## 事前作業(IKO使用時)
IKO使用時は、上記に加えて下記の作業が必要になります。

1. envs.shの編集  

    1.1 InterSystemsコンテナレジストリのクレデンシャル情報

    InterSystemsコンテナリポジトリへのクレデンシャルが必要です。  
    https://container.intersystems.com/　にWRCアカウントでログインしてください。
    使用したユーザ名、得られたDocker login passwordを下記と置き換えてください。

    ```bash
    export isccruser=_intersyetems_container_repo_username_here_
    export isccrpassword=_intersyetems_container_repo_token_here_
    ```

    1.2 ユーザ作成のコンテナリポジトリのクレデンシャル情報
    (ユーザ作成のプライベートリポジトリ上にある)ユーザ作成のイメージを使用する場合は、下記でクレデンシャルを指定してください。

    ```bash
    export cruser="xxxxxx"
    export crpassword="yyyyyyyyy"
    ```

2. IKOのインストーラ(HELM chart)入手  
公式ドキュメント  
https://docs.intersystems.com/components/csp/docbook/DocBook.UI.Page.cls?KEY=AIKO  
IKOを試される場合は、ご面倒ですが、IKOのキット(tar)をWRCから入手してください。(より自然な入手方法を検討中です)  
Software Distribution -> Components下にあるInterSystems Kubernetes Operatorです。  
解凍したtarのchartフォルダをgit cloneしたフォルダにコピーしてください。
    ```bash
    $ tar -xvf iris_operator-3.3.0.120-unix.tar.gz
    $ cp -r iris_operator-3.3.0.120/chart iris-k8s-vs2021/
    ```
    下記のような構造になるはずです。
    ```bash
    $ tree chart/
    chart/
    └── iris-operator
        ├── Chart.yaml
        ├── README.md
        ├── templates
        │   ├── NOTES.txt
        │   ├── _helpers.tpl
        │   ├── apiregistration.yaml
        │   ├── appcatalog-user-roles.yaml
        │   ├── cleaner.yaml
        │   ├── cluster-role-binding.yaml
        │   ├── cluster-role.yaml
        │   ├── deployment.yaml
        │   ├── mutating-webhook.yaml
        │   ├── service-account.yaml
        │   ├── service.yaml
        │   ├── user-roles.yaml
        │   └── validating-webhook.yaml
        └── values.yaml
    ```
3. HELMのインストール  

    ```bash
    $ curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
    ```

4. 評価ライセンスキーの入手  
IKOは、Shard/ミラーを構成するため製品版のIRISとライセンスキーを使用します。
IKOを試される場合は、ご面倒ですが、Shard及びミラーが有効なコンテナバージョン用のIRIS評価ライセンスキーを入手して、~/に配置してください。以後、このファイルは取り扱い注意です(間違ってpublicなレポジトリにpushしないよう)。

5. IRISパスワードの設定 

    [common.cpf](cpf/common.cpf)にパスワードハッシュ値を反映します。  

ここまでは事前に一度だけ実行しておき、以降は再利用するのが便利です。  
**ここ以降はAzureでコストが発生する操作を含みます。**

# VNET作成
```bash
$ az login
$ shell/aks-create-subnet.sh
```

# AKSクラスタの作成
```bash
$ shell/aks-create-aks-cluster.sh
```
> 数分程度、時間がかかります

```bash
$ kubectl get node
NAME                                STATUS   ROLES   AGE     VERSION
aks-nodepool1-35959336-vmss000000   Ready    agent   4m4s    v1.23.8
aks-nodepool1-35959336-vmss000001   Ready    agent   3m35s   v1.23.8
aks-nodepool1-35959336-vmss000002   Ready    agent   2m50s   v1.23.8
```

# Demo内容
[demo.txt](docs/demo.txt)を参照ください。

IKOを利用したデプロイを[Lens](https://k8slens.dev/)で表示するとこのようになります。
![lens1](docs/lens1.png)
![lens2](docs/lens2.png)

# 削除
## Demo開始前の状態に戻す
(Demo内容)を初期状態から再実行するには、下記を実行してください。Demo.txtで作成したリソースを全て削除します。
```bash
shell/reset-to-next-demo.sh
```
> 再度Demo.txtの操作を行った場合、イメージがK8s環境にpullされているので、初回に比べてPODの起動が早くなります。

## AKSクラスタを完全に削除
AKSクラスタを完全に削除するには下記を実行してください。
```bash
source shell/envs.sh
az group delete --name $aksrg --yes --no-wait
az group delete --name $rg --yes --no-wait
```

念のため、Azureのポータルで、下記のリソースグループが削除(もしくは内容が空)されていることを確認してください。
```bash
$ az group list --query "[?name=='iris-rg']"
[]
az group list --query "[?name=='iris-aks-rg']"
[]
```

次回は、「VNET作成」から再実行できます。

# IKOの動作
これを見れば、IKOが実際に何を行っているのかを知ることができます。
## IKOによるCPFの上書き設定内容
下記コマンドで、IKOが実施したcpf mergeの内容を確認ことが出来ます。
```bash
$ kubectl describe cm iris-vs2021-data-0
```

## IKOによるKubernetesの操作
下記コマンドで、IKOが作成したPODやServiceのyamlを出力することができます。

```bash
$ kubectl get pod iris-vs2021-data-0-0 -o yaml
$ kubectl get pod iris-vs2021-data-0-1 -o yaml
$ kubectl get statefulset iris-vs2021-data-0 -o yaml
$ kubectl get svc iris-vs2021 -o yaml
```
