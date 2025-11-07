学习目标

理解 Dashboard 的使用和结构

掌握 Pod、Deployment、Service 三大核心概念

理解它们之间的层级关系与生命周期

通过 Dashboard + 命令双视角管理资源

一、📊 Dashboard 概览：Kubernetes 的「可视化控制台」

Kubernetes Dashboard 是官方提供的 Web 界面，用于查看、管理和调试集群。

你可以在这里看到：

所有命名空间（Namespace）；

Pod、Deployment、Service、Job、ConfigMap 等资源；

容器日志与事件；

集群状态、节点资源使用情况。

启动方式（复习）：

minikube dashboard


输出示例：

🔌  Enabling dashboard ...
🤔  Verifying dashboard health ...
🚀  Launching proxy ...
🎉  Opening http://127.0.0.1:50219/api/v1/namespaces/kubernetes-dashboard/


访问后会看到左侧导航栏：
Workloads（工作负载）、Services（服务）、Config and Storage（配置与存储）、Cluster（集群资源）。

二、🧩 核心概念：Pod、Deployment、Service
1️⃣ Pod —— 最小执行单元（工厂里的“生产车间”）

定义：Pod 是 K8s 中可以被创建、调度、管理的最小运行单元。

本质：一组容器共享同一个网络和存储空间。

用途：一般一个 Pod 运行一个主容器（主业务），但可以有 sidecar 容器（辅助任务）。

📘 示例结构：

apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: web
    image: nginx
    ports:
    - containerPort: 80


执行：

kubectl apply -f my-pod.yaml
kubectl get pods
kubectl describe pod my-pod


在 Dashboard → Workloads → Pods 中，你会看到这个 Pod 出现在列表中。

2️⃣ Deployment —— 管理 Pod 的“调度主管”

定义：Deployment 是用于声明副本数量、版本更新、滚动升级的控制器。

作用：

自动维持指定数量的 Pod；

Pod 崩溃自动重建；

支持滚动升级（逐步替换旧版本）。

📘 示例结构：

apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80


执行：

kubectl apply -f web-deploy.yaml
kubectl get deployment
kubectl get pods


在 Dashboard → Workloads → Deployments
你会看到该 Deployment，点进去可查看副本数、滚动升级历史、事件日志。

3️⃣ Service —— 网络访问入口（“前台接待员”）

定义：Service 为一组 Pod 提供稳定的访问入口。
（因为 Pod 会频繁创建和销毁，它们的 IP 会变化）

作用：

让外部或内部服务能稳定访问；

支持负载均衡；

定义通信方式（ClusterIP / NodePort / LoadBalancer）。

📘 示例结构：

apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: NodePort


执行：

kubectl apply -f web-service.yaml
kubectl get svc


在 Dashboard → Discovery and Load Balancing → Services
你可以看到 Service 的端口映射（例如 80 → 30123），点击端口可直接访问应用。

三、🕸 三者关系图（超通俗版）
[ Deployment ]
     ↓  管理副本（replicas）
 ┌────────────────────────┐
 |        ReplicaSet       |
 └────────────────────────┘
     ↓  维护多个 Pod
 ┌────────────┐   ┌────────────┐   ┌────────────┐
 |   Pod #1   |   |   Pod #2   |   |   Pod #3   |
 |  (nginx)   |   |  (nginx)   |   |  (nginx)   |
 └────────────┘   └────────────┘   └────────────┘
     ↑
     |  通过 label (app=web)
     |
[ Service ]
    ↓ 提供统一访问入口
http://<NodeIP>:<NodePort>


📘 简单理解：

Deployment：告诉系统“我要3个Nginx副本”；

Pod：实际运行的容器单元；

Service：负责“给别人看门”，让外部能访问这3个Nginx。

四、🧠 在 Dashboard 中观察三者关系

打开 Dashboard

minikube dashboard


点击左侧导航栏：

Workloads → Deployments

点开 web-deploy
→ 查看其关联的 ReplicaSet 和 Pod

Discovery and Load Balancing → Services
→ 查看 web-service 与 Pod 的连接

在右上角 “YAML” 按钮中，你还能直接查看系统自动生成的资源定义文件。

五、🧪 实战任务：创建 + 可视化验证

1️⃣ 创建资源：

kubectl apply -f web-deploy.yaml
kubectl apply -f web-service.yaml


2️⃣ 查看终端输出：

kubectl get deploy,svc,pods


3️⃣ 打开 Dashboard 确认：

Deployment 下显示 3 个 Pod；

Service 下显示 1 个 NodePort；

Pod 状态均为 Running。

4️⃣ 测试访问：

minikube service web-service


浏览器中应该显示默认的 Nginx 页面 🟢

六、🧩 补充：Pod 的生命周期（Lifecycle）
阶段	描述
Pending	正在调度，还未启动容器
Running	容器已启动，正常运行中
Succeeded	任务完成，容器退出
Failed	启动失败或异常退出
CrashLoopBackOff	启动后立刻崩溃并反复重启

查看事件详情：

kubectl describe pod <pod-name>

七、📘 今日总结

✅ 理解了 Dashboard 的作用与导航结构；

✅ 掌握 Pod、Deployment、Service 三大核心概念；

✅ 通过 Dashboard 图形化理解它们的关系；

✅ 学会用 kubectl 与 Dashboard 双视角操作资源。

八、📗 今日任务清单
任务	命令	状态
启动 Dashboard	minikube dashboard	✅
创建 Deployment	kubectl apply -f web-deploy.yaml	✅
创建 Service	kubectl apply -f web-service.yaml	✅
查看三者关系	Dashboard → Workloads / Service	✅
访问应用	minikube service web-service	✅
记录学习笔记	~/k8s-learning/day5/day5.md	✍️