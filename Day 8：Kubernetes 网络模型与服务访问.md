Day 8：Kubernetes 网络模型与服务访问（ClusterIP / NodePort / Ingress）
🎯 学习目标

理解 Kubernetes 网络设计理念

掌握三种 Service 类型：ClusterIP、NodePort、Ingress

学会如何让外部访问集群中的应用

实战部署一个可从浏览器访问的 Web 服务

一、🌐 理论：Kubernetes 网络的三大原则

K8s 的网络设计非常优雅，核心理念是：

1️⃣ 每个 Pod 都有独立 IP（Pod IP）
→ Pod 与 Pod 之间可以直接通信（同集群内无需 NAT）

2️⃣ 同一节点和跨节点通信无差异
→ 网络平面由 CNI 插件（如 Flannel、Calico）统一管理

3️⃣ Pod、Service、外部世界三层网络统一路由
→ Pod 访问 Pod、外部访问 Service、Ingress 控制域名流量

📘 重点理解：

K8s 把所有通信都抽象成“Service”——一个稳定的访问入口。

二、🧩 Service 三种类型详解
🔹 1. ClusterIP —— 集群内访问（默认类型）

提供一个“虚拟 IP”，仅集群内可访问。

适合 Pod 间内部通信，如后端服务或数据库。

📘 示例：
创建 service-clusterip.yaml

apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080


执行：

kubectl apply -f service-clusterip.yaml
kubectl get svc


输出：

NAME               TYPE        CLUSTER-IP       PORT(S)   AGE
backend-service    ClusterIP   10.100.182.45    80/TCP    1m


只能在集群内部访问：

kubectl exec -it <pod> -- curl http://backend-service

🔹 2. NodePort —— 暴露给外部访问

会在每个 Node 的特定端口（30000~32767）开放服务；

外部访问方式：<NodeIP>:<NodePort>。

📘 示例：
创建 service-nodeport.yaml

apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort


执行：

kubectl apply -f service-nodeport.yaml
kubectl get svc nginx-nodeport


查看端口：

nginx-nodeport   NodePort   10.103.50.76   <none>   80:30080/TCP   2m


访问：

minikube service nginx-nodeport


或者直接浏览器打开：

http://127.0.0.1:30080


✅ 你会看到 Nginx 欢迎页。

🔹 3. Ingress —— 反向代理 + 路由控制（HTTP层）

Ingress 是一种 七层（L7）负载均衡机制；

可以根据 域名、路径 分流请求；

相当于集群内的“NGINX 网关”。

📘 架构理解：

[外部浏览器]
     ↓
[Ingress Controller (nginx-ingress)]
     ↓
[Service: web-service] → [Pod]

第一步：安装 Ingress Controller

Minikube 提供一键启用：

minikube addons enable ingress


验证：

kubectl get pods -n kube-system | grep ingress


你会看到：

ingress-nginx-controller-xxxx   Running   1/1

第二步：部署应用和 Service

创建 web-deploy.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
spec:
  replicas: 2
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
        image: nginx
        ports:
        - containerPort: 80


创建 web-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP


执行：

kubectl apply -f web-deploy.yaml
kubectl apply -f web-service.yaml

第三步：创建 Ingress 规则

创建 web-ingress.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  rules:
  - host: web.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80


执行：

kubectl apply -f web-ingress.yaml
kubectl get ingress


输出：

NAME          CLASS    HOSTS        ADDRESS        PORTS   AGE
web-ingress   <none>   web.local    192.168.49.2   80      1m

第四步：配置本地访问

在 macOS 上编辑 hosts 文件：

sudo vi /etc/hosts


添加：

192.168.49.2   web.local


（192.168.49.2 是 minikube ip 的结果）

保存后浏览器访问：

http://web.local


✅ 成功显示 Nginx 页面 🎉

三、🧠 三种 Service 类型总结表
类型	可访问范围	典型场景	访问方式
ClusterIP	集群内	Pod 间通信 / 内部服务	http://service-name:port
NodePort	集群外	简单外部访问	http://<NodeIP>:<NodePort>
Ingress	集群外（HTTP层）	多服务路由 / 域名访问	http://<host>/path
四、🕸 网络路径图解（通俗理解）
                +-------------------------+
                |   外部用户（浏览器）     |
                +-----------+-------------+
                            |
                     (HTTP Request)
                            ↓
                +-------------------------+
                |   Ingress Controller     |
                |  (Nginx / Traefik)      |
                +-----------+-------------+
                            |
                 路由匹配 (Host / Path)
                            ↓
                +-------------------------+
                |       Service            |
                |  (ClusterIP or NodePort) |
                +-----------+-------------+
                            |
                  负载均衡到多个 Pod
                            ↓
                +-------------------------+
                |          Pods            |
                +-------------------------+

五、🧪 今日实战任务汇总
步骤	文件	命令
创建 Deployment	web-deploy.yaml	kubectl apply -f web-deploy.yaml
创建 ClusterIP 服务	web-service.yaml	kubectl apply -f web-service.yaml
启用 Ingress		minikube addons enable ingress
创建 Ingress 路由	web-ingress.yaml	kubectl apply -f web-ingress.yaml
修改 /etc/hosts		添加 web.local 映射
浏览器访问		打开 http://web.local ✅
六、📘 今日总结

✅ 理解了 Kubernetes 的网络模型与三大访问方式；

✅ 掌握 ClusterIP、NodePort、Ingress 的区别与应用场景；

✅ 能让外部访问你的 Pod 服务；

✅ 学会通过 Ingress 使用域名和路径分流。

📗 今日任务清单
任务	命令	状态
启用 Ingress	minikube addons enable ingress	✅
部署 web 应用与 Service	kubectl apply -f web-deploy.yaml / web-service.yaml	✅
创建 Ingress 路由	kubectl apply -f web-ingress.yaml	✅
配置本地 hosts	/etc/hosts	✅
浏览器访问 http://web.local	✅	
记录学习笔记	~/k8s-learning/day8/day8.md	✍️