Day 11：ConfigMap 与 Secret（配置管理与安全凭据）
🎯 学习目标

理解 ConfigMap 与 Secret 的区别与作用

学会通过命令和 YAML 创建配置资源

掌握将配置注入 Pod 的两种方式（环境变量 & 文件挂载）

实战：使用 ConfigMap 动态修改 Nginx 配置页面

一、📖 理论概念
🔹 ConfigMap —— 非敏感配置管理

ConfigMap 用于存放普通配置数据，比如：

应用环境（APP_ENV=dev）；

连接地址（DB_HOST=10.0.0.2）；

文本配置文件（如 app.conf）。

📘 类比：

ConfigMap 就像“应用的配置文件柜”，让镜像保持通用，而环境差异由配置控制。

🔹 Secret —— 敏感数据管理

Secret 用于存放敏感信息，比如：

数据库用户名密码；

API Token；

TLS 证书。

📘 类比：

Secret 是 Kubernetes 的“保险柜”，内容经过 Base64 编码，可受 RBAC 控制访问。

二、🧩 创建 ConfigMap
✅ 方法一：命令行创建
kubectl create configmap app-config \
  --from-literal=APP_MODE=production \
  --from-literal=APP_VERSION=1.0


查看：

kubectl get configmap app-config -o yaml

✅ 方法二：YAML 文件定义

创建 configmap.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: web-config
data:
  APP_COLOR: "blue"
  APP_ENV: "staging"


执行：

kubectl apply -f configmap.yaml
kubectl get cm web-config -o yaml

三、🧾 创建 Secret
✅ 方法一：命令行创建
kubectl create secret generic db-secret \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASSWORD=123456


查看：

kubectl get secret db-secret
kubectl describe secret db-secret


查看解码内容（仅用于学习环境）：

kubectl get secret db-secret -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode


输出：

123456

✅ 方法二：YAML 文件定义

创建 secret.yaml

apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  username: YWRtaW4=        # admin
  password: MTIzNDU2        # 123456


执行：

kubectl apply -f secret.yaml

四、⚙️ Pod 使用 ConfigMap 和 Secret
🧩 方法一：注入为环境变量

创建 pod-env.yaml

apiVersion: v1
kind: Pod
metadata:
  name: env-demo
spec:
  containers:
  - name: web
    image: nginx
    envFrom:
    - configMapRef:
        name: web-config
    - secretRef:
        name: my-secret


执行：

kubectl apply -f pod-env.yaml
kubectl exec -it env-demo -- env | grep APP_
kubectl exec -it env-demo -- env | grep DB_


输出示例：

APP_COLOR=blue
APP_ENV=staging
DB_USER=admin
DB_PASSWORD=123456

🧩 方法二：挂载为文件（Volume）

创建 pod-volume.yaml

apiVersion: v1
kind: Pod
metadata:
  name: volume-demo
spec:
  containers:
  - name: web
    image: nginx
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
    - name: secret-volume
      mountPath: /etc/secret
      readOnly: true
  volumes:
  - name: config-volume
    configMap:
      name: web-config
  - name: secret-volume
    secret:
      secretName: my-secret


执行：

kubectl apply -f pod-volume.yaml


验证：

kubectl exec -it volume-demo -- ls /etc/config
kubectl exec -it volume-demo -- cat /etc/config/APP_COLOR
kubectl exec -it volume-demo -- ls /etc/secret
kubectl exec -it volume-demo -- cat /etc/secret/username | base64 --decode


✅ 说明 ConfigMap 与 Secret 已成功挂载。

五、🧠 ConfigMap vs Secret 对比
特性	ConfigMap	Secret
内容	非敏感数据	敏感信息
数据格式	明文	Base64 编码
常见用途	环境变量、配置文件	密码、令牌、证书
安全级别	一般	高（RBAC 可限制访问）
挂载方式	env / volume	env / volume
六、🧩 实战：动态修改 Nginx 页面内容

创建 welcome-config.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: welcome-html
data:
  index.html: |
    <html>
    <body style="background-color:lightblue;">
      <h1>Hello from ConfigMap!</h1>
    </body>
    </html>


创建 nginx-cm-pod.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-cm
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
  volumes:
  - name: html
    configMap:
      name: welcome-html


执行：

kubectl apply -f welcome-config.yaml
kubectl apply -f nginx-cm-pod.yaml


访问页面：

kubectl port-forward nginx-cm 8080:80


浏览器访问 http://localhost:8080
✅ 显示 “Hello from ConfigMap!”

修改 ConfigMap：

kubectl edit configmap welcome-html


刷新浏览器可看到页面内容实时变化（Nginx 立即加载新文件）。

七、📗 今日任务清单
任务	命令	状态
创建 ConfigMap	kubectl apply -f configmap.yaml	✅
创建 Secret	kubectl apply -f secret.yaml	✅
Pod 环境变量注入	kubectl apply -f pod-env.yaml	✅
Pod 文件挂载	kubectl apply -f pod-volume.yaml	✅
动态修改 Nginx 页面	kubectl edit configmap welcome-html	✅
保存学习笔记	~/k8s-learning/day11/day11-configmap-secret.md	✍️
八、📘 今日总结

✅ 你学会了使用 ConfigMap 管理普通配置；

✅ 你理解了 Secret 的安全性与编码机制；

✅ 掌握了两种注入方式：环境变量 & 文件挂载；

✅ 实现了应用的配置热更新。