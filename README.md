# 実行に際して
StatefulSetを使用したデプロイは、Community版を使用しますので、どなたでも実行可能です。  
InterSystems Kubernetes Operatorは製品版IRISを使用するため、有効なWRCアカウントが必要となります。

# 事前作業
## 事前作業

事前作業を実施する環境として、Ubuntu20.04をご用意ください。
1. az cli, kubectlのインストール  

    az cli
    ```bash
    $ curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    ```
    kubectl
    ```bash
    $ sudo az aks install-cli
    ```

2. HELMのインストール  
    ```bash
    $ curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
    ```

3. サービスプリンシパル作成  
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

4. envs.shの編集  
利用者に関するセンシティブな情報は全てshell/envs.shに格納しています。取り扱い注意です。

    4.1 サービスプリンシパルの情報

    (事前作業 3.サービスプリンシパル作成)で取得したappId,passwordを下記と置き換えてください。(引用符不要)

    ```bash
    export appid=_azure_appid_here_
    export password=_azure_password_here_
    ```

    4.2 InterSystemsコンテナレジストリのクレデンシャル情報

    IKOを試される場合は、InterSystemsコンテナリポジトリへのクレデンシャルが必要です。  
    https://container.intersystems.com/　にWRCアカウントでログインしてください。
    使用したユーザ名、得られたDocker login passwordを下記と置き換えてください。(引用符不要)

    ```bash
    export iscuser=_intersyetems_container_repo_username_here_
    export isccrpassword=_intersyetems_container_repo_token_here_
    ```

5. IRISパスワードの設定(任意)  
この作業を行わない場合のパスワードはSYSです。
IRIS用のPassword Hashの作成及び定義への反映を行います。  
公式ドキュメント  
https://docs.intersystems.com/iris20201/csp/docbookj/Doc.View.cls?KEY=ADOCK#ADOCK_iris_images_password_auth

    ```bash
    $ docker run --rm -it containers.intersystems.com/intersystems/passwordhash:1.0
    Enter password:
    Enter password again:
    PasswordHash=e2ccf25a9b4bdff9bf7beae900d3a1f86d0f3176,o26ec72cuser@irishost:~$
    user@irishost:~$
    ```
    上記のように、出力が改行されずプロンプトとつながってしまうかもしれません。切れ目にご留意ください。
    必要なハッシュ値はe2ccf25a9b4bdff9bf7beae900d3a1f86d0f3176,o26ec72cです。

    [iris-configmap-cpf.yaml](yaml/iris-configmap-cpf.yaml)にここで得たハッシュ値を反映します。  
    
## 事前作業(IKO使用時)
IKO使用時は、上記に加えて下記の作業が必要になります。

1. IKOのインストーラ(HELM chart)入手  
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

2. 評価ライセンスキーの入手  
IKOは、Shard/ミラーを構成するため製品版のIRISとライセンスキーを使用します。
IKOを試される場合は、ご面倒ですが、Shard及びミラーが有効なコンテナバージョン用のIRIS評価ライセンスキーを入手して./iris.keyと置き換えてください。

3. IRISパスワードの設定(任意)

    [compute.cpf](cpf/compute.cpf), [data.cpf](cpf/data.cpf)にパスワードハッシュ値を反映します。  

    ```bash
    yaml/iris-iko.yaml
    ```

ここまでは事前に一度だけ実行しておき、以降は再利用するのが便利です。  
**ここ以降はAzureでコストが発生する操作を含みます。**

# VNET作成
```bash
$ source shell/envs.sh
$ az login
$ shell/aks-create-subnet.sh
```

# AKSクラスタの作成
```bash
$ shell/aks-create-aks-cluster.sh
```
(数分程度、時間がかかります)

```bash
$ kubectl get node
NAME                                STATUS   ROLES   AGE   VERSION
aks-nodepool1-12005123-vmss000000   Ready    agent   19m   v1.18.14
aks-nodepool1-12005123-vmss000001   Ready    agent   19m   v1.18.14
aks-nodepool1-12005123-vmss000002   Ready    agent   19m   v1.18.14
```

# Demo内容
docs/demo.txtを参照ください。

# 削除

(Demo内容)を初期状態から再実行するには、下記を実行してください。Demoで作成したリソースを全て削除します。
```bash
shell/reset-to-next-demo.sh
```
(イメージがK8s環境にpullされているので、初回に比べてPODの起動が早くなります)

AKSクラスタを完全に削除するには下記を実行してください。
```bash
source shell/envs.sh
az group delete --name $aksrg --yes --no-wait
az group delete --name $rg --yes --no-wait
```
次回は、(VNET作成)から再実行できます。

念のため、Azureのポータルで、下記のリソースグループが削除(もしくは内容が空)されていることを確認してください。
```bash
iris-rg
iris-aks-rg
```