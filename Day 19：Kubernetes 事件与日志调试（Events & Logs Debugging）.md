Day 19：Kubernetes 事件与日志调试（Events & Logs Debugging）
🎯 今日学习目标

理解 Kubernetes 事件（Event）是什么

掌握 kubectl describe 调试 Pod / Deployment / Node

掌握 kubectl logs 查看容器内部日志

学会排查常见错误（镜像拉取失败、健康检查失败等）

通过实际示例进行完整调试流程

一、📖 什么是 Kubernetes Event？

Event 是 Kubernetes 自动生成的诊断信息：

✔ 什么时候调度 Pod？
✔ 为什么调度失败？
✔ 为什么镜像拉不下来？
✔ 为什么探针失败？
✔ 为什么创建了 Pod 却起不来？

事件具有：

类型：Normal / Warning

源：kubelet / scheduler / kube-proxy / deployment-controller

时间

描述信息

查询事件命令
kubectl get events --sort-by='.lastTimestamp'


更清晰：

kubectl describe pod <podname>


因为事件会在末尾按时间顺序显示，非常适合调试。

二、📘 kubectl describe：调试 Pod 的第一步

describe 会显示：

Pod 状态

镜像拉取

探针

资源调度

事件（Events）

挂载卷

示例：

kubectl describe pod web


输出重点：

Events:
  Warning  FailedScheduling   pod didn't match node selector
  Warning  FailedMount        unable to mount volumes
  Normal   Pulled             Successfully pulled image
  Warning  BackOff            Back-off restarting failed container


📘 每一条事件都是线索。

三、📘 kubectl logs：查看容器内部日志

基础用法：

kubectl logs <pod>


某个容器：

kubectl logs <pod> -c <container>


实时日志：

kubectl logs -f <pod>


查看上一次崩溃日志：

kubectl logs <pod> --previous

四、🧪 实战：制造错误并排查（最重要）

我们创建一个错误的镜像：

bad-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: bad-pod
spec:
  containers:
  - name: bad
    image: nginx:99   # ❌ nginx 99 版本不存在


应用：

kubectl apply -f bad-pod.yaml
kubectl get pods


你会看到：

STATUS: ImagePullBackOff

🔍 Step 1：describe 查看事件
kubectl describe pod bad-pod


关键输出：

Failed to pull image "nginx:99": manifest not found
Back-off pulling image "nginx:99"


✔ 很清楚：镜像不存在

🔍 Step 2：修复

把镜像改成正确版本：

image: nginx:1.25


重新 apply：

kubectl apply -f bad-pod.yaml

五、🧪 再制造一个 CrashLoopBackOff
crash-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: crash-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo start; exit 1"]   # ❌ 自动退出


应用：

kubectl apply -f crash-pod.yaml
kubectl get pods


状态：

CrashLoopBackOff

🔍 Step 1：查看容器日志
kubectl logs crash-pod


输出：

start


（然后退出）

🔍 Step 2：查看详细事件
kubectl describe pod crash-pod


你会看到：

Back-off restarting failed container


✔ 原因：容器错误退出导致无限重启

六、🧠 Kubernetes 错误排查金字塔

这是最实用的调试模型👇

1️⃣ kubectl get pods
     ↓（知道状态）

2️⃣ kubectl describe pod
     ↓（知道事件）

3️⃣ kubectl logs <pod>
     ↓（看程序日志）

4️⃣ kubectl logs --previous <pod>
     ↓（查看崩溃前的日志）

5️⃣ kubectl describe node <node>
     ↓（节点是否资源不足）

6️⃣ kubectl get events --sort-by='.metadata.creationTimestamp'


掌握这一套，你可以 debug 99% 的 K8s 问题。

七、🧪 综合测试（Busybox 版）

创建 busybox 测试 Pod：

apiVersion: v1
kind: Pod
metadata:
  name: debug-box
spec:
  containers:
  - name: box
    image: busybox
    command: ["sh", "-c", "sleep 3600"]


进入：

kubectl exec -it debug-box -- sh


你可以：

nslookup <service>
ping <pod-ip>
curl <service>
cat /etc/resolv.conf


Busybox 是调试 K8s 网络 / DNS / 服务最通用的工具。

八、📗 今日任务清单
任务	文件	命令	状态
创建错误镜像 Pod	bad-pod.yaml	kubectl apply	⬜
使用 describe 检查错误	—	kubectl describe pod bad-pod	⬜
创建 CrashLoopBackOff Pod	crash-pod.yaml	kubectl apply	⬜
使用 logs 查看日志	—	kubectl logs crash-pod	⬜
使用 busybox 测试网络	debug-box	kubectl exec	⬜
记录学习笔记	~/k8s-learning/day19-debug.md	✍️	
九、📘 今日总结

你已经掌握 Kubernetes 最核心的调试能力：

你知道 Pod 状态不是问题本身，而是症状

你会用 describe 查看所有事件

你知道 logs 才能看到容器内部问题

你知道怎么定位镜像拉取失败问题

你知道怎么处理 CrashLoopBackOff

你掌握了 busybox 调试集群的通用方法

你现在已经具备“初级 K8s 运维工程师”的完整调试能力。