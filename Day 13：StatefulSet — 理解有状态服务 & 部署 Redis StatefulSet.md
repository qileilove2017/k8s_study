学习目标

理解 StatefulSet 与 Deployment 的区别

掌握有状态应用的 3 大核心概念：
• 稳定网络标识（Stable DNS）
• 稳定存储（PV/PVC 自动绑定）
• 有序部署与删除（Ordered Deployment）

学会部署一个 Redis StatefulSet

验证每个 Redis Pod 具有固定名称与独立存储

一、📖 什么是 StatefulSet？

StatefulSet = 有状态服务的控制器。

它解决 Deployment 无法解决的问题：

特性	Deployment	StatefulSet
Pod 名称	随机，如 pod-xyz	固定，如 redis-0、redis-1
存储卷	随机挂载	与 Pod 1:1 绑定，永久保持
网络标识	Pod IP 会变	DNS 永久固定（如 redis-0.redis）
启动顺序	无序	严格顺序 0 → 1 → 2
适用场景	无状态（Nginx）	有状态（Redis、MySQL、Kafka）

📘 关键特性总结：

StatefulSet = 持久身份 + 持久存储 + 有序管理

二、📦 部署 Redis StatefulSet（核心实战）

我们将部署一个最小可用的 Redis 集群（1 主 / 多副本可自行扩展）。

Step 1：创建 Headless Service（没有 ClusterIP）

StatefulSet 必须依赖一个 无头服务（Headless Service） 才能实现 Pod 的固定 DNS。

创建 redis-headless.yaml：

apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  clusterIP: None
  selector:
    app: redis
  ports:
  - port: 6379


执行：

kubectl apply -f redis-headless.yaml

Step 2：部署 Redis StatefulSet

创建 redis-statefulset.yaml：

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
spec:
  serviceName: "redis"
  replicas: 3
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7.0
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redis-data
          mountPath: /data
        command: ["redis-server", "--appendonly", "yes"]
  volumeClaimTemplates:
  - metadata:
      name: redis-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi


执行：

kubectl apply -f redis-statefulset.yaml

三、🧪 验证 StatefulSet 行为
1. 查看 Pod 名称是否顺序创建
kubectl get pods -l app=redis


输出：

redis-0
redis-1
redis-2


仅 StatefulSet 会保证顺序创建与命名。

2. 查看 PVC 是否自动生成
kubectl get pvc


你会看到：

redis-data-redis-0
redis-data-redis-1
redis-data-redis-2


📘 每个 Pod 都会有一个独立、持久的存储卷。
删除 Pod 也不会删除 PVC → 数据永存。

3. 测试每个 Pod 的 DNS 固定身份

进入任意 Pod：

kubectl exec -it redis-0 -- sh


执行 ping：

ping redis-1.redis


所有 Pod 的 DNS 都是可预期的：

redis-0.redis
redis-1.redis
redis-2.redis


📘 这就是 StatefulSet 最大的魔法 —— Pod DNS 永远不会变。

4. 测试 Redis 是否可读写数据

写入数据（在 redis-0 中）：

kubectl exec -it redis-0 -- redis-cli set foo bar
kubectl exec -it redis-0 -- redis-cli get foo


输出：

bar


重启 Pod：

kubectl delete pod redis-0


重新进入：

kubectl exec -it redis-0 -- redis-cli get foo


仍然输出：

bar


✔️ 数据持久化成功（PVC 未丢失数据）

四、🧠 StatefulSet 的关键知识点
1. Pod 有唯一编号（0 开始）

redis-0

redis-1

redis-2
编号不会因为重启而改变。

2. 每个 Pod 都有固定 DNS

格式：

<pod-name>.<headless-service-name>


如：

redis-0.redis
redis-1.redis

3. 每个 Pod 有独立的 PVC

复制副本不会共享存储。

4. 有序部署与删除

创建顺序：0 → 1 → 2

删除顺序：2 → 1 → 0

用于分布式数据库的安全扩容。

5. 常见场景
场景	是否适合 StatefulSet
Redis replica 集群	✔️
MySQL 主从集群	✔️
Kafka / Zookeeper	✔️
配置中心如 Etcd	✔️
Nginx/前端服务	❌（使用 Deployment）

StatefulSet 专为有状态服务而生。

五、📗 今日任务清单
任务	文件	命令	状态
创建 Redis Headless Service	redis-headless.yaml	kubectl apply	✅
部署 StatefulSet	redis-statefulset.yaml	kubectl apply	✅
验证 Pod 顺序与命名	kubectl get pods		✅
验证自动生成 PVC	kubectl get pvc		✅
测试数据持久化	kubectl exec redis-0 -- redis-cli		✅
记录学习笔记	~/k8s-learning/day13/day13-statefulset.md	✍️	
六、📘 今日总结

你理解了 StatefulSet = 有状态服务控制器

掌握了 StatefulSet 的 3 大核心能力：
✔️ 稳定网络身份
✔️ 稳定持久存储
✔️ 有序部署与删除

实战部署了 Redis StatefulSet

成功验证了数据持久化、固定命名、顺序扩容等行为

你现在具备了部署任意有状态数据库的基础能力（MongoDB、MySQL、Kafka 等）。