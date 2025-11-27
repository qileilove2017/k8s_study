学习目标

理解 DaemonSet 的定义与工作机制

掌握 DaemonSet 与 Deployment 的区别

理解“每节点一个 Pod”的调度逻辑

实战：在每个节点部署 Node Exporter，实现节点级监控

一、📖 理论：什么是 DaemonSet？

DaemonSet 是一种特殊的 Kubernetes 控制器，用于在每个节点上自动运行一个 Pod。

📘 类比：

Deployment 管理应用副本，
DaemonSet 管理“系统守护进程”。

🔹 核心特性
特性	说明
部署方式	每个节点一个 Pod
节点加入	新节点加入时自动部署 Pod
节点删除	节点移除时自动清理 Pod
常见用途	日志收集（Fluentd）、监控（Node Exporter、Promtail）、安全代理、系统探针
🔹 与 Deployment 的区别
特性	Deployment	DaemonSet
调度目标	任意节点	所有节点
Pod 数量	固定副本数	与节点数相同
常见场景	Web / API 服务	Agent / 监控 / 安全服务
新节点行为	不自动创建 Pod	自动分配新 Pod
二、🧩 DaemonSet 的运行机制

当你创建 DaemonSet 后，调度器会确保：

集群中每个符合条件的节点上都有一个该 Pod；

当新节点加入时，自动在其上部署；

当节点删除时，自动回收对应 Pod。

📘 如果你有 5 个节点，就会看到 5 个 Pod，每个节点恰好一个。

三、📦 实战：部署 Node Exporter DaemonSet

Node Exporter 是 Prometheus 官方的节点监控组件。
它会收集 CPU、内存、磁盘、网络等指标。

我们将使用 DaemonSet 让它在所有节点上自动运行。

Step 1：创建 ServiceAccount 与 RBAC（可选）

用于在集群中安全运行 Node Exporter。

node-exporter-rbac.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: node-exporter
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-exporter
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-exporter
roleRef:
  kind: ClusterRole
  name: node-exporter
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: node-exporter
  namespace: kube-system


执行：

kubectl apply -f node-exporter-rbac.yaml

Step 2：创建 DaemonSet 部署文件

node-exporter-daemonset.yaml

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: kube-system
  labels:
    app: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      serviceAccountName: node-exporter
      hostNetwork: true
      hostPID: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.7.0
        ports:
        - name: metrics
          containerPort: 9100
          hostPort: 9100
        securityContext:
          privileged: true
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        - name: root
          mountPath: /rootfs
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      - name: root
        hostPath:
          path: /


执行：

kubectl apply -f node-exporter-daemonset.yaml

Step 3：验证部署状态

查看 DaemonSet：

kubectl get daemonset -n kube-system


输出示例：

NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-exporter    2         2         2       2            2           <none>          1m


查看 Pod：

kubectl get pods -n kube-system -l app=node-exporter -o wide


输出示例：

NAME                  NODE       STATUS   IP
node-exporter-abc12   node1      Running  10.0.0.5
node-exporter-def34   node2      Running  10.0.0.6


📘 每个节点都有一个 Pod 正在运行。

Step 4：访问 Node Exporter

验证端口：

kubectl port-forward -n kube-system node-exporter-abc12 9100:9100


浏览器访问：

http://localhost:9100/metrics


✅ 你会看到 CPU、内存、网络、磁盘等 Prometheus 格式的指标数据。

四、🧠 DaemonSet 高级技巧
功能	示例	说明
仅在特定节点运行	nodeSelector: { "kubernetes.io/os": "linux" }	限制部署范围
指定调度标签	tolerations / affinity	与节点污点结合使用
与 Prometheus 集成	通过 ServiceMonitor 自动采集	监控集群资源
自动重启	支持与 Deployment 相同的滚动更新策略	确保长期稳定运行
五、🧩 DaemonSet 可视化理解
+-------------------------+        +-------------------------+
| Node1                  |        | Node2                  |
|-------------------------|        |-------------------------|
| node-exporter Pod       |        | node-exporter Pod       |
| hostPort:9100           |        | hostPort:9100           |
| Collects system metrics |        | Collects system metrics |
+-------------------------+        +-------------------------+
           ↑                                    ↑
           └─────────── Prometheus scrapes ─────┘


📘 无论节点数量多少，DaemonSet 会自动保持“一节点一代理”的结构。

六、📗 今日任务清单
任务	文件	命令	状态
创建 RBAC 权限	node-exporter-rbac.yaml	kubectl apply	✅
部署 Node Exporter DaemonSet	node-exporter-daemonset.yaml	kubectl apply	✅
查看运行状态	kubectl get ds,pods -n kube-system	✅	
验证节点指标接口	浏览器访问 http://localhost:9100/metrics	✅	
保存学习笔记	~/k8s-learning/day14/day14-daemonset.md	✍️	
七、📘 今日总结

✅ 理解了 DaemonSet 的用途与机制：为每个节点部署一个守护进程

✅ 掌握了典型应用场景：监控代理、日志收集、安全防护

✅ 成功部署了 Node Exporter 并采集节点指标

✅ 熟悉了 DaemonSet 的 YAML 结构与调度逻辑