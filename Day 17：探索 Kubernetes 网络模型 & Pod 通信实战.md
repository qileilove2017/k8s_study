Day 17：探索 Kubernetes 网络模型 & Pod 通信实战
🎯 今日学习目标

理解 Pod 网络模型（CNI）

理解 Service 如何提供负载均衡与 DNS

掌握 Pod → Pod、Pod → Service、Service → Pod 的通信路径

使用 busybox 验证 Pod 间通信与 DNS 解析

一、📖 Pod 网络模型核心原理（为什么 Pod 之间能互相通信？）

“Kubernetes 的设计原则：每个 Pod 都必须拥有一个可被集群任意节点直接访问的唯一 IP”

这依赖 CNI 网络插件（Flannel、Calico、Cilium 等）实现。

K8s 的网络有 3 条规则：

所有 Pod 必须在一个可互通的扁平网络里
Pod IP 全局唯一，不需要 NAT。

Node（宿主机）必须能直接访问 Pod IP

Pod 与 Service 之间必须能互通
利用虚拟 IP（ClusterIP）+ kube-proxy 实现负载均衡。

📘 Pod 网络的本质：

每个 Node 都被分配一个 Pod 子网，Pod 通过 CNI 虚拟网桥连接到这个子网。

一个常见的示例：

Node A Pod 子网：10.244.1.0/24
Node B Pod 子网：10.244.2.0/24


Pod IP 如：

10.244.1.5  
10.244.2.9


无论在哪个节点，都能互通。

二、📘 Service 是如何实现 DNS 的？

当你创建一个 Service，例如：

kind: Service
metadata:
  name: my-service


Kube-DNS 会自动创建 DNS 名称：

my-service.default.svc.cluster.local


Service 负责两件事：

提供固定的虚拟 IP（ClusterIP）

自动负载均衡到对应 Pod

三、🔍 实战验证：Pod 间通信 + Service DNS
Step 1：创建两个简单 Pod
pod-a.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-a
  labels:
    app: pod-a
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "while true; do echo 'A alive'; sleep 5; done"]

pod-b.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-b
  labels:
    app: pod-b
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "while true; do echo 'B alive'; sleep 5; done"]


应用：

kubectl apply -f pod-a.yaml
kubectl apply -f pod-b.yaml

Step 2：查询 Pod IP
kubectl get pods -o wide


示例输出：

NAME    IP             NODE
pod-a   10.244.1.5     node1
pod-b   10.244.2.9     node2


即使在不同节点，仍然能互通。

Step 3：登录 pod-a 测试 ping pod-b

进入 pod-a：

kubectl exec -it pod-a -- sh


测试通信：

ping 10.244.2.9


如果 ping 不支持，用 wget：

wget -qO- http://10.244.2.9


✔ Pod → Pod IP 直接互通

四、📦 使用 busybox 测试 Service DNS

现在我们创建一个 Service：

svc-a.yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-a
spec:
  selector:
    app: pod-a
  ports:
  - port: 80
    targetPort: 80


虽然 pod-a 并没有监听 80 端口，我们只用它测试 DNS。

应用：

kubectl apply -f svc-a.yaml
kubectl get svc


输出：

NAME      TYPE        CLUSTER-IP      PORT
svc-a     ClusterIP   10.96.123.4     80/TCP

Step 4：从 busybox 验证 DNS
kubectl exec -it pod-b -- sh


查询 DNS：

nslookup svc-a


输出类似：

Server:   10.96.0.10
Name:     svc-a.default.svc.cluster.local
Address:  10.96.123.4


访问 Service：

wget -qO- svc-a


✔ DNS 解析成功
✔ Service 名称在 cluster 内可访问

五、📘 总结图（网络数据流）
                           +----------------------+
                           |   Cluster DNS        |
                           |   svc-a.default.svc  |
                           +----------+-----------+
                                      |
                                      v
        +---------------------+    ClusterIP    +---------------------+
        |       pod-a         |<--------------- |      pod-b          |
        |   10.244.1.5        |                 |   10.244.2.9        |
        +---------------------+                 +---------------------+
                  ^                                         ^
                  |                                         |
          nodeA subnet                              nodeB subnet

六、📗 今日任务清单
任务	文件	命令	状态
创建 Pod A、Pod B	pod-a.yaml, pod-b.yaml	kubectl apply	⬜
获取 Pod IP	kubectl get pods -o wide		⬜
Pod → Pod 测试通信	kubectl exec pod-a	⬜	
创建 Service 并测试 DNS	svc-a.yaml	nslookup svc-a	⬜
总结 network 学习笔记	~/k8s-learning/day17-network.md	✍️	
七、📘 今日总结

你理解了 Pod 网 → Service 网 → Node 网

理解了 DNS 解析与 ClusterIP

学会用 busybox 测试 Pod 间通信

理解 Service 如何提供名字解析与负载均衡

你的 K8s 网络基础已经“通了”