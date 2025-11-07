☸️ Day 9：理解 Namespace 与 Label
🎯 学习目标

理解 Namespace 的作用与场景

掌握 Label 与 Selector 的使用

学会在命令行中过滤、分组、隔离资源

实战：创建独立命名空间与标签筛选部署

一、📖 Namespace（命名空间）
🔹 概念

Namespace 用于在同一个集群中逻辑隔离资源。

简单来说，它就像操作系统中的“文件夹”，用来分类和隔离。

一个集群可以有多个命名空间（Namespace），不同命名空间之间的资源相互独立：

不同 Namespace 可以存在同名资源；

资源默认属于 default 命名空间；

系统内置命名空间：

kube-system（系统组件）

kube-public（公开资源）

default（用户默认命名空间）

🔹 使用场景

不同环境隔离（如 dev / test / prod）；

不同团队隔离（如 frontend / backend / ops）；

权限控制（RBAC 基于 Namespace 生效）。

二、🧩 Namespace 基本操作
✅ 查看命名空间
kubectl get namespace


输出：

NAME              STATUS   AGE
default           Active   3d
kube-system       Active   3d
kube-public       Active   3d
kube-node-lease   Active   3d

✅ 创建命名空间
kubectl create namespace dev


验证：

kubectl get ns


输出：

NAME        STATUS   AGE
default     Active   3d
dev         Active   1m

✅ 在特定命名空间中创建资源

创建 nginx-dev.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-dev
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80


执行：

kubectl apply -f nginx-dev.yaml
kubectl get pods -n dev


输出：

NAME        READY   STATUS    AGE
nginx-dev   1/1     Running   15s

✅ 临时切换命名空间
kubectl config set-context --current --namespace=dev


之后运行 kubectl get pods 默认就会使用 dev 命名空间。

恢复默认：

kubectl config set-context --current --namespace=default

三、🏷 Label（标签）
🔹 概念

Label 是附加在资源上的键值对（key=value），用于分组、筛选和管理资源。

它就像贴在资源上的“标签”，比如“部门=前端”、“环境=生产”。

📘 示例：

metadata:
  labels:
    app: nginx
    env: dev

🔹 常见用途

Pod 调度选择（Service、Deployment 使用 label 匹配目标）；

批量筛选资源；

监控与日志聚合分组；

灰度发布（区分新旧版本 Pod）。

四、🧩 Label 基本操作
✅ 创建带标签的 Pod
kubectl run nginx --image=nginx --labels="env=dev,app=frontend"


查看标签：

kubectl get pods --show-labels


输出：

NAME     READY   STATUS    LABELS
nginx    1/1     Running   app=frontend,env=dev

✅ 修改 / 添加标签
kubectl label pod nginx version=v1


查看结果：

kubectl get pod nginx --show-labels


输出：

NAME     READY   STATUS    LABELS
nginx    1/1     Running   app=frontend,env=dev,version=v1

✅ 删除标签
kubectl label pod nginx version-

✅ 根据标签筛选
kubectl get pods -l app=frontend
kubectl get pods -l 'env in (dev,prod)'

五、🔗 Label 与 Selector 的关系

Label 是贴在资源上的“标记”；
Selector 是根据 Label “选择资源”的机制。

📘 例如：

apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80


说明：

Service 会查找所有带有 app=frontend 标签的 Pod；

这些 Pod 会自动加入负载均衡。

六、🧩 实战任务：按环境区分部署

创建两个命名空间：

kubectl create ns dev
kubectl create ns prod


分别部署两个版本：

kubectl run web-dev --image=nginx --labels="env=dev,app=web" -n dev
kubectl run web-prod --image=nginx --labels="env=prod,app=web" -n prod


查看：

kubectl get pods -A -l app=web


输出：

NAMESPACE   NAME       STATUS    LABELS
dev         web-dev    Running   app=web,env=dev
prod        web-prod   Running   app=web,env=prod

七、🧠 可视化理解
+-----------------------------------------------------------+
|                    Kubernetes 集群                        |
|-----------------------------------------------------------|
|  Namespace: dev       |   Namespace: prod                 |
|  ------------------   |   ------------------------------  |
|  Pod: web-dev         |   Pod: web-prod                   |
|  Labels: app=web,env=dev | Labels: app=web,env=prod       |
+-----------------------------------------------------------+


Namespace 隔离环境；Label 标识属性；Selector 按标签选目标。

八、📗 今日任务清单
任务	命令	状态
创建命名空间 dev/prod	kubectl create ns dev/prod	✅
在特定命名空间部署 Pod	kubectl apply -f nginx-dev.yaml	✅
创建并查看标签	kubectl run nginx --labels="env=dev,app=frontend"	✅
使用 selector 筛选资源	kubectl get pods -l app=frontend	✅
修改当前命名空间上下文	kubectl config set-context --current --namespace=dev	✅
记录学习笔记	~/k8s-learning/day9/day9-namespace-label.md	✍️
九、📘 今日总结

✅ Namespace 让你在一个集群中实现逻辑隔离；

✅ Label 让你用标签管理、筛选、部署资源；

✅ Service、Deployment 等控制器通过 Selector 选择目标 Pod；

✅ Namespace + Label = 高效分层管理集群。