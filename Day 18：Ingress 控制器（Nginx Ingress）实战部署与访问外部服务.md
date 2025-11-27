Day 18：Ingress 控制器（Nginx Ingress）实战部署与访问外部服务
🎯 今日学习目标

理解 Ingress / Ingress Controller 的架构

区分 Service（ClusterIP/NodePort）与 Ingress

使用官方 ingress-nginx 部署 Ingress Controller

创建 Ingress 规则，实现通过域名访问服务

验证 Ingress 是否工作

一、📖 为什么需要 Ingress？（很重要）

在 Kubernetes 中，Service 有三种暴露方式：

类型	特点	适用场景
ClusterIP	集群内部访问	默认
NodePort	暴露到 NodeIP:Port	对外访问简单，但难管理
LoadBalancer	云厂商创建 LB	生产常用，但成本高

但当你需要：

✔ 域名访问
✔ 多路径路由
✔ 多域名绑定
✔ TLS（HTTPS）
✔ 灰度发布（Canary）

NodePort / LB 都不够灵活。

✨ Ingress 控制器是企业级入口，统一管理所有流量。

二、📘 Ingress 架构模型（必须理解）

Ingress 本身 不是 流量入口。
Ingress Controller 才是实际入口。

二者关系：

User → Ingress Controller (Nginx) → Ingress 规则 → Service → Pod


因此：

Ingress：声明路由（规则）

Ingress Controller：实际工作、监听规则并转发流量

三、📦 部署 Nginx Ingress Controller（官方版本）

你已经在 mac + k3d/k8s 环境 → 使用 NodePort 模式部署最合适。

Step 1：安装 ingress-nginx（官方 YAML）

执行官方安装：

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml


查看资源：

kubectl get all -n ingress-nginx


你应该看到：

Deployment：ingress-nginx-controller

Service：ingress-nginx-controller

Pod

ConfigMap

RBAC 规则

Step 2：查看 Ingress Controller 的暴露方式
kubectl get svc -n ingress-nginx


输出类似（NodePort 模式）：

ingress-nginx-controller   NodePort   10.0.20.5   <none>   80:30342/TCP   443:32451/TCP


这表示：

外部访问地址 = NodeIP:30342

外部访问 HTTPS = NodeIP:32451

四、🧪 创建一个测试服务（Nginx）
nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-demo
  template:
    metadata:
      labels:
        app: web-demo
    spec:
      containers:
      - name: nginx
        image: nginx:latest

nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-demo
spec:
  selector:
    app: web-demo
  ports:
  - port: 80
    targetPort: 80


应用：

kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

五、📘 创建 Ingress 路由规则（域名 → Service）

我们将用一个虚拟域名： demo.local

web-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: demo.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-demo
            port:
              number: 80


应用：

kubectl apply -f web-ingress.yaml

六、🧪 测试 Ingress 路由
Step 1：找到 NodeIP
kubectl get nodes -o wide


例如：

node1   192.168.1.10

Step 2：找到 Ingress 的 NodePort
kubectl get svc -n ingress-nginx


假设 NodePort 为 30342

Step 3：本地添加 hosts 映射（mac）

编辑 hosts：

sudo nano /etc/hosts


添加：

192.168.1.10   demo.local

Step 4：访问 Ingress

浏览器或 curl：

curl http://demo.local:30342


输出 Nginx 默认页面：

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>


✔ 你的 Ingress 已经成功工作！
✔ 你现在可以使用域名访问 K8s 内的服务

七、📘 可视化理解（非常重要）
             ┌───────────────────────────────┐
             │   ingress-nginx-controller    │
             │  (监听 80/443，解析 Ingress)   │
             └───────────────┬───────────────┘
                             │
                             ▼
                 ┌────────────────────┐
                 │    Ingress 规则     │
                 │ demo.local → web-demo:80
                 └───────────┬────────┘
                             │
                             ▼
                ┌────────────────────────┐
                │     Service: web-demo   │
                └───────────┬────────────┘
                            │ (kube-proxy LB)
                            ▼
                     Pod(nginx) × 2

八、📗 今日任务清单
任务	文件	命令	状态
安装 ingress-nginx	官方 deploy.yaml	kubectl apply	⬜
创建 Nginx Deployment & Service	nginx-deployment.yaml	apply	⬜
创建 Ingress 规则	web-ingress.yaml	apply	⬜
修改 /etc/hosts 映射测试域名	—	curl demo.local:NodePort	⬜
记录学习笔记	~/k8s-learning/day18-ingress.md	✍️	
九、📘 今日总结

今天你完成了 Kubernetes 网络中最重要的一步：

你掌握了 Ingress vs Service 的区别

你安装了生产级流量入口：ingress-nginx

你学会了创建 Ingress 规则

你掌握了域名到服务的转发

你可以从外部访问集群内部的 Pod

你的 Kubernetes 服务发布能力已经从新手提升到了“专业级运维”。