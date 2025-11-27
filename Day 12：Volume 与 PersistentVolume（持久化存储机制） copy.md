Day 12：Volume 与 PersistentVolume（持久化存储机制）
🎯 学习目标

理解 Kubernetes 存储的分层结构

掌握 Volume、PersistentVolume（PV）、PersistentVolumeClaim（PVC）的概念与关系

学会在 Pod 中挂载 PVC 实现数据持久化

实战：让 Nginx 写入的数据在 Pod 删除后仍然保留

一、📖 理论：为什么需要持久化？

在 Kubernetes 中，Pod 是短暂的（Ephemeral）。
当 Pod 因重启、调度或升级被删除后，其容器文件系统中的数据也随之消失。

📘 举例：

如果你在一个 Nginx Pod 的 /usr/share/nginx/html 中写入文件，当 Pod 删除后，文件也会消失。

因此，需要一种机制能在 Pod 被删除后保留数据，这就是 Volume 与 PersistentVolume 的职责。

二、🧩 三层存储架构模型
层级	对象	作用
应用层	Volume	挂载到 Pod 的存储目录（临时或持久）
用户层	PersistentVolumeClaim（PVC）	用户发起的“存储请求”
系统层	PersistentVolume（PV）	管理员提供的“实际存储资源”

📘 类比：

Pod = 用户
PVC = 申请单
PV = 仓库

三、💾 Volume（普通卷）

Volume 是与 Pod 生命周期绑定的临时存储。
Pod 删除 → Volume 数据消失。

示例：emptyDir

创建 pod-emptydir.yaml

apiVersion: v1
kind: Pod
metadata:
  name: cache-pod
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sh", "-c", "echo Hello > /cache/test.txt && sleep 3600"]
    volumeMounts:
    - name: cache-volume
      mountPath: /cache
  volumes:
  - name: cache-volume
    emptyDir: {}


执行：

kubectl apply -f pod-emptydir.yaml
kubectl exec -it cache-pod -- cat /cache/test.txt


输出：

Hello


删除 Pod 再重建：

kubectl delete pod cache-pod
kubectl apply -f pod-emptydir.yaml
kubectl exec -it cache-pod -- ls /cache


❌ 文件消失 → 说明这是临时卷。

四、📦 PersistentVolume（PV）

PV 是 Kubernetes 管理的实际存储资源。
可以来自本地磁盘、NFS、云存储（如 Azure Disk、AWS EBS）等。

示例：本地 PV

创建 pv.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /data/pv-demo


执行：

sudo mkdir -p /data/pv-demo
kubectl apply -f pv.yaml
kubectl get pv


输出：

NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   AGE
local-pv    1Gi        RWO            Retain           Available           manual         2m

五、🧾 PersistentVolumeClaim（PVC）

PVC 是用户对存储的请求，描述自己需要多少容量、访问模式等。
K8s 会自动将 PVC 与合适的 PV 绑定。

创建 pvc.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: web-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi


执行：

kubectl apply -f pvc.yaml
kubectl get pvc


输出：

NAME       STATUS   VOLUME     CAPACITY   ACCESS MODES   AGE
web-pvc    Bound    local-pv   1Gi        RWO            1m


📘 表示 PVC 已成功绑定到 PV。

六、🔗 Pod 使用 PVC 实现数据持久化

创建 pod-pvc.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-pv-demo
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: web-storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: web-storage
    persistentVolumeClaim:
      claimName: web-pvc


执行：

kubectl apply -f pod-pvc.yaml


在容器中写入文件：

kubectl exec -it nginx-pv-demo -- sh -c "echo 'Hello Persistent Volume!' > /usr/share/nginx/html/index.html"


暴露访问：

kubectl port-forward nginx-pv-demo 8080:80


访问：

http://localhost:8080


✅ 显示页面内容：
Hello Persistent Volume!

删除并重建 Pod：

kubectl delete pod nginx-pv-demo
kubectl apply -f pod-pvc.yaml


再次访问页面，内容仍然存在 🎉
→ 数据已被 PV 保留，实现持久化。

七、🧠 PV 生命周期策略
策略	说明
Retain	删除 PVC 后保留数据，需手动清理
Delete	删除 PVC 时自动删除底层存储
Recycle（已废弃）	清空后重用
八、📘 可视化理解
+-----------------------------+
| PersistentVolume (PV)       |
| capacity: 1Gi               |
| accessMode: ReadWriteOnce   |
+--------------+--------------+
               ↑
               | 绑定 (Bound)
+--------------+--------------+
| PersistentVolumeClaim (PVC) |
| request: 500Mi              |
| accessMode: ReadWriteOnce   |
+--------------+--------------+
               ↑
               | 挂载到 Pod
+--------------+--------------+
| Pod: nginx-pv-demo          |
| mountPath: /usr/share/nginx/html |
+-----------------------------+

九、📗 今日任务清单
任务	文件	命令	状态
创建 PV	pv.yaml	kubectl apply -f pv.yaml	✅
创建 PVC	pvc.yaml	kubectl apply -f pvc.yaml	✅
绑定 PVC 至 Pod	pod-pvc.yaml	kubectl apply -f pod-pvc.yaml	✅
写入与验证持久化数据		kubectl exec -it nginx-pv-demo -- ...	✅
删除 Pod 验证数据持久性		✅	
记录学习笔记	~/k8s-learning/day12/day12-pv-pvc.md	✍️	
十、📘 今日总结

✅ 理解 Volume、PV、PVC 三层关系；

✅ 掌握从“临时卷”到“持久卷”的演化；

✅ 能创建 PVC 并挂载到 Pod，实现数据持久化；

✅ 理解存储生命周期与回收策略。