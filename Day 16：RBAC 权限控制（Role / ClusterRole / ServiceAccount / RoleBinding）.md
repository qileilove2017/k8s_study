Day 16：探索 RBAC 权限控制（Role、ClusterRole、ServiceAccount）
🎯 学习目标

理解 RBAC（基于角色的访问控制）的模型

掌握 Role / ClusterRole 的作用与区别

学会创建 ServiceAccount

通过 RoleBinding 限制权限

实战：创建一个只能读取 Pods 的受限账户

一、📖 什么是 RBAC？

RBAC = Role-Based Access Control
K8s 的权限控制通过 4 个对象来完成：

(1) ServiceAccount           —— 身份（谁）
(2) Role / ClusterRole       —— 权限（能干什么）
(3) RoleBinding / CRBinding  —— 授权（绑定）


📘 通俗理解：

元素	功能	类比
ServiceAccount	账号身份	用户账号
Role	命名空间级权限	部门权限
ClusterRole	集群级权限	系统管理员权限
RoleBinding	在某个 Namespace 授权	给部门分配权限
ClusterRoleBinding	全局授权	给所有项目授予权限
二、🧠 Role 与 ClusterRole 的区别
项目	Role	ClusterRole
作用范围	当前命名空间	整个集群
可授予权限	仅 namespace 资源	所有资源（包括节点、命名空间）
使用场景	Dev/Prod 环境隔离	管理 Node、PV、Namespace

📘 例子：

一个前端应用 Pod，只能访问自己所在 Namespace → Role

运维管理员需要读写所有节点 → ClusterRole

三、👤 创建 ServiceAccount（身份）

创建一个受限账号：read-pods-sa

serviceaccount.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: read-pods-sa
  namespace: default


执行：

kubectl apply -f serviceaccount.yaml
kubectl get sa

四、📘 创建 Role（限制权限）

我们定义一个角色：
✔ 只能读取 Pods
✔ 不能删除
✔ 不能修改
✔ 不能访问其他资源

role-read-pods.yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]


执行：

kubectl apply -f role-read-pods.yaml
kubectl get role

五、🔗 RoleBinding（将账号与权限绑定）

将 read-pods-sa 与 pod-reader 绑定：

rolebinding-read-pods.yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: read-pods-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io


执行：

kubectl apply -f rolebinding-read-pods.yaml

六、🧪 实战：验证权限是否生效
Step 1：启动一个使用该 ServiceAccount 的 Pod

test-pod.yaml

apiVersion: v1
kind: Pod
metadata:
  name: test-rbac
spec:
  serviceAccountName: read-pods-sa
  containers:
  - name: busybox
    image: busybox
    command: ["sh", "-c", "sleep 3600"]


执行：

kubectl apply -f test-pod.yaml

Step 2：在 Pod 内执行 kubectl（通过 API 调用）

进入 Pod：

kubectl exec -it test-rbac -- sh


测试读 Pods：

wget -qO- \
  --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  https://kubernetes.default.svc/api/v1/namespaces/default/pods \
  --no-check-certificate


✔ 会输出 Pods 列表（成功）

Step 3：测试“无法删除 Pod”

在 Pod 内执行：

wget -qO- \
  --method=DELETE \
  --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  https://kubernetes.default.svc/api/v1/namespaces/default/pods/test-rbac \
  --no-check-certificate


❌ 返回 “Forbidden”

{"kind":"Status","code":403,"reason":"Forbidden","message":"pods is forbidden"}


说明：
👉 RBAC 权限限制成功

七、🧠 RBAC 权限体系总结
[ServiceAccount]
       ↓ (通过 Binding 关联)
[Role / ClusterRole]
       ↓ (描述权限)
[Resources: pods, svc, nodes...]

八、📘 小抄：常用 RBAC 示例
✔ 允许读取 ConfigMap 和 Secret
verbs: ["get", "list"]
resources: ["configmaps", "secrets"]

✔ 允许操作 Deployment
resources: ["deployments"]
verbs: ["get", "list", "update", "patch"]

✔ 允许访问所有命名空间（使用 ClusterRole）
kind: ClusterRole
resources: ["pods"]
verbs: ["get", "list", "watch"]

九、📗 今日任务清单
任务	文件	命令	状态
创建 ServiceAccount	serviceaccount.yaml	kubectl apply	✅
创建 Role（读取 Pods）	role-read-pods.yaml	kubectl apply	✅
绑定权限	rolebinding-read-pods.yaml	kubectl apply	✅
测试权限（API 授权）	exec + wget		✅
保存笔记	~/k8s-learning/day16/day16-rbac.md	✍️	
🔚 今日总结

你已掌握 Kubernetes RBAC 的三大核心组件：
✔ Role / ClusterRole（权限）
✔ ServiceAccount（身份）
✔ RoleBinding / ClusterRoleBinding（授权）

能创建仅能读 Pod 的受限账户

能使用 SA 在 Pod 内验证权限

这是企业级安全必备技能