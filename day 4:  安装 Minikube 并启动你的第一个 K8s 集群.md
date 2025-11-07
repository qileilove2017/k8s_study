学习目标

理解 Minikube 是什么

在 macOS 上安装 Minikube

启动集群并验证 K8s 组件运行正常

学会使用 kubectl 与 Minikube 交互

访问 Dashboard 图形界面

一、📖 理论：什么是 Minikube？

Minikube 是一个轻量级的 Kubernetes 实验环境，专为本地开发和学习设计。

通俗理解：

你电脑上的“小型 Kubernetes 工厂”，功能完整，但体积迷你。

Minikube 会在本地创建一个虚拟机（或 Docker 容器），里面包含：

kube-apiserver

scheduler

controller-manager

etcd

kubelet

kube-proxy

因此它是一个单节点完整集群（Single-Node Cluster）。

二、🔧 安装 Minikube（mac 环境）
1️⃣ 使用 Homebrew 安装（推荐）
brew install minikube


验证：

minikube version


输出示例：

minikube version: v1.34.0
commit: 1c2d293f4b34a3d983f

三、🚀 启动第一个 K8s 集群

执行以下命令启动：

minikube start --driver=docker


说明：
--driver=docker 表示使用 Docker 容器作为虚拟节点运行环境，速度最快，且无须额外的虚拟机软件。

启动时 Minikube 会自动：

下载 Kubernetes 组件镜像；

创建虚拟节点；

启动 kubelet、scheduler、controller；

生成默认的 kubeconfig。

启动过程完成后，你会看到：
🌟  Done! kubectl is now configured to use "minikube" cluster and "default" namespace


这意味着 kubectl 已自动连接到你的本地集群。

验证连接：

kubectl get nodes


输出示例：

NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   2m    v1.31.0

四、🌐 访问 Dashboard 图形界面

Minikube 自带可视化管理面板 Dashboard。

启动：

minikube dashboard


此命令会自动在浏览器中打开：

http://127.0.0.1:XXXXX/api/v1/namespaces/kubernetes-dashboard/...


你将在浏览器中看到集群的 Pod、Service、Deployment、事件等图形界面。

💡技巧：如果浏览器未自动打开，可以手动访问命令行输出的 URL。

五、🧩 部署第一个应用（Nginx）

创建 nginx-deployment.yaml：

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80


执行：

kubectl apply -f nginx-deployment.yaml


查看状态：

kubectl get pods


输出：

NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-678d45ff9b-9x8gq   1/1     Running   0          30s
nginx-deployment-678d45ff9b-xm6f2   1/1     Running   0          30s


暴露服务：

kubectl expose deployment nginx-deployment --type=NodePort --port=80


查看服务信息：

kubectl get svc


输出：

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
nginx-deployment     NodePort    10.102.182.211   <none>        80:30123/TCP   1m


通过 Minikube 打开服务：

minikube service nginx-deployment


浏览器中将自动打开一个运行中的 Nginx 页面 🎉

六、📦 集群常用命令速查表
操作	命令	说明
查看节点	kubectl get nodes	显示集群节点状态
查看 Pod	kubectl get pods -A	查看所有命名空间 Pod
停止集群	minikube stop	暂停集群（节省资源）
启动集群	minikube start	恢复运行
删除集群	minikube delete	清理环境
查看 IP	minikube ip	获取集群主机 IP
查看 Dashboard	minikube dashboard	打开可视化界面
七、🧠 故障排查（常见问题）
问题	可能原因	解决方法
❌ Exiting due to HOST_HOME_PERMISSION	权限问题	运行 sudo chown -R $USER ~/.minikube
❌ Docker driver not found	未安装 Docker Desktop	安装 Docker 并确认运行
❌ Unable to pull image	网络访问受限	在 minikube 中配置国内镜像源
❌ kubectl get nodes 超时	kubeconfig 未配置	运行 minikube update-context 修复
八、✅ 今日成果
任务	状态
安装 Minikube	✅
启动本地集群	✅
验证节点状态	✅
部署并访问 Nginx	✅
打开 K8s Dashboard	✅
记录笔记 ~/k8s-learning/day4/day4.md	✍️
九、📘 今日总结

Minikube 是运行本地 K8s 的最简方式；

你已拥有一个完整的集群（控制面 + 数据面）；

能使用 kubectl 部署、暴露、访问应用；

K8s 的所有核心概念（Pod、Deployment、Service）都可以在这个环境中实验。