Day 3：安装 kubectl 并掌握基本操作
🎯 学习目标

了解 kubectl 是什么、为什么要用它

在 macOS 上安装 kubectl

学会最常用的 kubectl 命令（查看、创建、删除、调试）

能独立与 K8s 集群交互（Minikube / Docker Desktop 集群）

一、📖 理论：kubectl 是什么？

kubectl 是 Kubernetes 的命令行工具（CLI），它通过调用 kube-apiserver 的 REST API 来管理整个集群。

你所有的操作（比如创建 Pod、查看状态、删除服务），本质上都是：

kubectl → kube-apiserver → etcd


可以理解为：

kubectl 是你发指令的遥控器，而 kube-apiserver 是中央指挥部。

二、🔧 安装 kubectl（mac 环境）
✅ 方式一：通过 Homebrew（推荐）
brew install kubectl


安装完成后验证：

kubectl version --client


输出示例：

Client Version: v1.31.2
Kustomize Version: v5.4.1


如果你已经安装了 Docker Desktop，它通常自带一个本地 Kubernetes 集群。
此时可以用：

kubectl cluster-info


查看是否能连接成功。

✅ 方式二（可选）：手动安装（curl 方式）
curl -LO "https://dl.k8s.io/release/$(curl -L -s \
https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/


验证：

kubectl version --client

三、🧠 kubectl 的基本结构与用法

命令格式：

kubectl [command] [TYPE] [NAME] [flags]


例如：

kubectl get pods
kubectl describe pod nginx-pod
kubectl delete pod nginx-pod

参数	含义
command	操作类型（get / describe / create / delete / apply）
TYPE	资源类型（pod, deployment, service, node, etc.）
NAME	资源名称
flags	附加选项（例如 -n 指定命名空间）
四、🔍 常用命令速查表
操作目标	命令	说明
查看所有命名空间	kubectl get ns	列出所有 namespace
查看所有 Pod	kubectl get pods -A	查看所有命名空间的 Pod
查看 Deployment	kubectl get deploy	
查看详细信息	kubectl describe pod <name>	包含事件、容器状态
创建资源	kubectl apply -f pod.yaml	从 YAML 文件创建
删除资源	kubectl delete -f pod.yaml	从 YAML 文件删除
实时查看日志	kubectl logs -f <pod>	类似 tail -f
进入容器	kubectl exec -it <pod> -- bash	交互式进入容器
查看集群节点	kubectl get nodes	查看所有 Node 状态
切换命名空间	kubectl config set-context --current --namespace=<ns>	
五、🧩 实战练习：运行第一个 Pod

创建文件 nginx-pod.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80


执行：

kubectl apply -f nginx-pod.yaml


验证：

kubectl get pods


输出类似：

NAME         READY   STATUS    RESTARTS   AGE
nginx-pod    1/1     Running   0          20s


进入容器：

kubectl exec -it nginx-pod -- bash


删除 Pod：

kubectl delete pod nginx-pod

六、🧰 技巧：kubectl 命令补全（可选）

开启自动补全：

brew install bash-completion
echo "source <(kubectl completion bash)" >> ~/.bash_profile
source ~/.bash_profile


现在在命令行中输入 kubectl get [Tab][Tab]，就能自动提示资源类型。

七、🚀 小练习（Day 3 任务）
任务	命令	是否完成
安装 kubectl	brew install kubectl	✅
查看版本	kubectl version --client	✅
创建第一个 Pod	kubectl apply -f nginx-pod.yaml	✅
查看 Pod 状态	kubectl get pods	✅
删除 Pod	kubectl delete pod nginx-pod	✅
写入学习笔记 ~/k8s-learning/day3/day3.md	✍️	
八、📘 今日总结

kubectl 是 Kubernetes 的“遥控器”

所有命令本质都是向 kube-apiserver 发送 REST 请求

你已经能在本地操作 YAML 文件创建和删除 Pod

这些技能是进入下一步——Minikube 启动完整集群（Day 4） 的前置条件