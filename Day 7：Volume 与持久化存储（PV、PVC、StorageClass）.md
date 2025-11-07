Day 7：Volume 与持久化存储（PV、PVC、StorageClass）
🎯 学习目标

理解 Volume 与 Pod 生命周期的关系

理解 PV / PVC / StorageClass 三层存储抽象

掌握如何为 Pod 持久化数据

实战部署一个带数据卷的 Nginx

一、📖 理论概念
🔹 为什么需要持久化？

默认情况下，Pod 删除或重建后，内部的数据会消失，因为：

Pod = 临时运行的容器实例，生命周期短暂。

例如：

MySQL 容器重启后，数据库表会丢失；

Web 应用缓存、上传文件消失。

因此我们需要一种独立于 Pod 生命周期的存储机制。

二、🧩 基本概念层级

Kubernetes 的存储体系可理解为三层结构：

层级	资源对象	说明
应用层	Pod 使用 Volume	容器直接挂载存储目录
用户层	PersistentVolumeClaim（PVC）	应用提出“我要存储”的请求
系统层	PersistentVolume（PV）	管理员提供实际存储资源
动态层	StorageClass	定义自动创建 PV 的规则

📘 类比：

用户（Pod） → 申请单（PVC） → 仓库（PV） → 仓库模板（StorageClass）

三、📦 Volume（普通数据卷）

Volume 是与 Pod 一起定义的存储目录。Pod 销毁后，数据会丢失。
适用于缓存、临时文件等场景。

示例：emptyDir（临时卷）
apiVersion: v1
kind: Pod
metadata:
  name: cache-pod
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sh", "-c", "echo hello > /cache/test.txt && sleep 3600"]
    volumeMounts:
    - name: cache-volume
      mountPath: /cache
  volumes:
  - name: cache-volume
    emptyDir: {}


执行：

kubectl apply -f cache-pod.yaml
kubectl exec -it cache-pod -- cat /cache/test.txt


删除 Pod 再重新创建后：

kubectl delete pod cache-pod
kubectl apply -f cache-pod.yaml
kubectl exec -it cache-pod -- ls /cache


📍 文件消失 —— 因为这是临时卷。

四、💾 PersistentVolume（PV）

PV 是管理员在集群中预先配置的实际存储资源，类似“仓库”。

由集群管理员创建；

包含容量、访问模式、回收策略；

可以来自 NFS、Azure Disk、AWS EBS、local path 等。

示例：本地 PV
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

五、🧾 PersistentVolumeClaim（PVC）

PVC 是用户的“申请单”，声明自己需要多少存储。

示例：
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


PVC 会自动绑定到符合条件的 PV。
绑定成功状态为：Bound。

六、🔗 Pod 使用 PVC

创建 pod-pvc.yaml：

apiVersion: v1
kind: Pod
metadata:
  name: nginx-pv-demo
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - mountPath: /usr/share/nginx/html
      name: web-storage
  volumes:
  - name: web-storage
    persistentVolumeClaim:
      claimName: web-pvc


执行：

kubectl apply -f pod-pvc.yaml


写入文件：

kubectl exec -it nginx-pv-demo -- sh -c "echo 'Hello PV' > /usr/share/nginx/html/index.html"


端口转发：

kubectl port-forward nginx-pv-demo 8080:80


浏览器访问：

http://localhost:8080


你会看到页面输出：

Hello PV


删除 Pod 后重新创建：

kubectl delete pod nginx-pv-demo
kubectl apply -f pod-pvc.yaml


再次访问，文件仍然存在 ✅ —— 数据已持久化！

七、⚙️ StorageClass（动态供应）

StorageClass 定义了如何动态创建 PV。
当 PVC 没有匹配的 PV 时，系统会根据 StorageClass 自动生成。

示例：
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer


执行：

kubectl apply -f storageclass.yaml
kubectl get sc


在云环境（如 GCP、Azure、AWS）中，StorageClass 会自动调用云存储 API 创建卷。
在 Minikube 本地环境中，我们可使用 standard 默认类。

查看：

kubectl get storageclass


输出示例：

NAME                 PROVISIONER               AGE
standard (default)   k8s.io/minikube-hostpath  5d

八、📘 PV 生命周期（回收策略）
策略	说明
Retain	保留数据，需手动清理
Delete	删除 PV 同时删除底层存储
Recycle（废弃）	清空数据后重用（已不推荐）
九、🧠 实战任务总结
步骤	文件	命令
创建 PV	pv.yaml	kubectl apply -f pv.yaml
创建 PVC	pvc.yaml	kubectl apply -f pvc.yaml
部署 Pod 挂载 PVC	pod-pvc.yaml	kubectl apply -f pod-pvc.yaml
写入测试数据	kubectl exec -it nginx-pv-demo -- echo 'Hello PV' > /usr/share/nginx/html/index.html	
验证数据持久化	删除 Pod 后重新创建	✅
查看绑定状态	kubectl get pv,pvc	✅
🔍 可视化理解（图解）
        +-----------------------------+
        |     StorageClass (模板)     |
        +-------------+---------------+
                      ↓ 动态创建
        +-----------------------------+
        | PersistentVolume (仓库)      |
        |   - storage: 1Gi            |
        |   - accessModes: RWO        |
        +-------------+---------------+
                      ↑ 绑定
        +-----------------------------+
        | PersistentVolumeClaim (申请单) |
        |   - request: 500Mi           |
        +-------------+---------------+
                      ↑ 挂载
        +-----------------------------+
        | Pod (应用)                   |
        |   - volumeMounts: /data      |
        +-----------------------------+

🧩 今日收获总结

✅ 理解 Volume、PV、PVC、StorageClass 的分层关系；

✅ 学会创建静态与动态卷；

✅ 能为 Pod 提供持久化存储；

✅ 明白云环境和本地环境的差异。

📗 今日任务清单
任务	命令	状态
创建 PV / PVC	kubectl apply -f pv.yaml / pvc.yaml	✅
部署挂载 Pod	kubectl apply -f pod-pvc.yaml	✅
测试数据持久化	删除 Pod 后验证数据	✅
查看绑定关系	kubectl get pv,pvc	✅
记录学习笔记	~/k8s-learning/day7/day7.md	✍️