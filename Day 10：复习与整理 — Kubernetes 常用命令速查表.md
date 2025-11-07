Day 10：复习与整理 — Kubernetes 常用命令速查表
🎯 学习目标

梳理 kubectl 的基本结构与使用模式

掌握最常用的命令组合

形成通用工作习惯（CRUD 模型）

整理一份一眼就能查到的命令清单

一、📖 kubectl 命令结构

所有命令都遵循以下模式：

kubectl [command] [TYPE] [NAME] [flags]


command：执行动作（get、describe、apply、delete、logs、exec…）

TYPE：资源类型（pod、service、deployment、configmap、secret、namespace…）

NAME：资源名称（可省略，表示全部）

flags：附加选项（-n、-l、-o、--watch…）

📘 例：

kubectl get pods -n dev -o wide


意思是：“在 dev 命名空间下，获取所有 Pod 的详细信息。”

二、🧩 最常用命令分类整理
✅ 资源查看类（get）
操作	命令	说明
查看节点	kubectl get nodes	查看所有节点
查看 Pod	kubectl get pods	查看当前命名空间 Pod
查看 Pod（含命名空间）	kubectl get pods -A	显示所有命名空间的 Pod
查看 Deployment	kubectl get deploy	
查看 Service	kubectl get svc	
查看 ConfigMap	kubectl get cm	
查看 Secret	kubectl get secret	
查看命名空间	kubectl get ns	
查看所有资源	kubectl get all	
查看更详细信息	kubectl get pods -o wide	包括节点 IP、Pod IP、镜像等
持续监听变化	kubectl get pods --watch	实时刷新资源状态
✅ 资源描述类（describe）
操作	命令	说明
查看 Pod 详情	kubectl describe pod <pod-name>	包含事件、容器状态、调度节点等
查看 Deployment 详情	kubectl describe deployment <name>	查看副本数、滚动升级情况
查看 Service 详情	kubectl describe svc <name>	显示端口、选择器、后端 Pod
查看 Node 详情	kubectl describe node <node-name>	节点容量、分配资源、污点
✅ 资源创建与更新类（apply / create）
操作	命令	说明
从文件创建	kubectl apply -f <file>.yaml	推荐方式（可重复执行更新）
创建命名空间	kubectl create namespace dev	
创建 ConfigMap	kubectl create configmap app-config --from-literal=key=value	
创建 Secret	kubectl create secret generic mysecret --from-literal=pwd=123	
创建 Pod（命令行）	kubectl run nginx --image=nginx	快速启动测试 Pod
创建 Service（命令行）	kubectl expose pod nginx --port=80 --type=NodePort	
部署应用	kubectl apply -f deployment.yaml	
✅ 删除类（delete）
操作	命令	说明
删除资源	kubectl delete pod <name>	
删除所有 Pod	kubectl delete pods --all	
删除 Deployment	kubectl delete deploy <name>	
删除 Service	kubectl delete svc <name>	
删除命名空间	kubectl delete ns <name>	
删除文件定义的所有资源	kubectl delete -f <file>.yaml	
✅ 日志与调试类（logs / exec / port-forward）
操作	命令	说明
查看日志	kubectl logs <pod-name>	查看单容器 Pod 的日志
实时查看日志	kubectl logs -f <pod-name>	类似 tail -f
多容器 Pod 查看	kubectl logs <pod-name> -c <container>	指定容器名称
进入容器交互	kubectl exec -it <pod-name> -- bash	
端口转发	kubectl port-forward <pod-name> 8080:80	将本地 8080 映射到容器 80
查看事件	kubectl get events --sort-by=.metadata.creationTimestamp	按时间排序的事件日志
查看集群组件状态	kubectl get componentstatuses	
✅ 标签与选择器类（label / -l）
操作	命令	说明
为资源添加标签	kubectl label pod <pod-name> env=dev	
删除标签	kubectl label pod <pod-name> env-	
按标签筛选	kubectl get pods -l app=nginx	
多条件筛选	kubectl get pods -l 'env in (dev,prod)'	
✅ 命名空间类（namespace）
操作	命令	说明
查看命名空间	kubectl get ns	
创建命名空间	kubectl create ns dev	
删除命名空间	kubectl delete ns dev	
临时在指定命名空间执行命令	kubectl get pods -n dev	
切换默认命名空间	kubectl config set-context --current --namespace=dev	
✅ 状态与资源监控类
操作	命令	说明
查看节点状态	kubectl get nodes -o wide	
查看资源使用情况	kubectl top pods / kubectl top nodes	需启用 Metrics Server
查看所有事件	kubectl get events	
查看所有 API 资源类型	kubectl api-resources	
三、📦 常用命令组合（实践范例）
1️⃣ 快速创建并暴露 Nginx
kubectl run nginx --image=nginx
kubectl expose pod nginx --port=80 --type=NodePort
minikube service nginx

2️⃣ 监控 Deployment 滚动升级
kubectl rollout status deployment myapp
kubectl rollout history deployment myapp
kubectl rollout undo deployment myapp

3️⃣ 调试失败 Pod
kubectl describe pod <name>
kubectl logs <name> --previous
kubectl exec -it <name> -- sh

4️⃣ 查看集群架构信息
kubectl get componentstatuses
kubectl cluster-info
kubectl version --short

四、🧠 命令使用思维模型（CRUD + Debug）
操作类别	核心命令	关键动词
创建 (Create)	create / apply -f	产生资源
读取 (Read)	get / describe	查看状态
更新 (Update)	apply -f / edit	修改资源
删除 (Delete)	delete	清理资源
调试 (Debug)	logs / exec / port-forward	定位问题
五、📘 今日总结

✅ 理解 kubectl 的语法结构与命令逻辑；

✅ 熟悉最常见的 7 大类命令（查看 / 创建 / 删除 / 调试 / 标签 / 命名空间 / 监控）；

✅ 能独立执行常规的资源管理任务；

✅ 建立起 “CRUD + Debug” 的系统思维模型。

📗 今日任务清单
任务	状态
复习所有命令结构	✅
整理命令速查表	✅
练习 get / apply / describe / logs / exec	✅
保存学习笔记至 ~/k8s-learning/day10/day10-cheatsheet.md	✍️