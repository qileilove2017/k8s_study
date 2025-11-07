Day 6：ConfigMap 与 Secret（配置与凭据管理）
🎯 学习目标

理解 ConfigMap 与 Secret 的作用与区别

学会创建与查看 ConfigMap / Secret

掌握挂载到 Pod 的两种方式（环境变量与 Volume）

实战：为 Nginx 动态加载配置文件

一、📖 理论概念
🔹 什么是 ConfigMap？

ConfigMap 用于存放普通配置数据（非敏感信息），例如：

环境变量（ENV 值）

应用配置文件内容（如 config.json）

命令行参数或系统参数

🧠 通俗理解：

ConfigMap = 应用的“配置文件夹”，在运行时自动加载到容器中。

🔹 什么是 Secret？

Secret 用于存放敏感数据，例如：

数据库密码

API Token

TLS 证书

🧠 通俗理解：

Secret = 加密后的“保险柜”，只能被授权的 Pod 打开。

ConfigMap 与 Secret 的最大区别是：
Secret 的数据会经过 Base64 编码，并且访问权限更严格。

二、🧩 创建 ConfigMap
✅ 方法一：命令行直接创建
kubectl create configmap app-config \
  --from-literal=APP_MODE=production \
  --from-literal=APP_VERSION=1.0


查看：

kubectl get configmap
kubectl describe configmap app-config

✅ 方法二：通过 YAML 定义

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

三、🧩 创建 Secret
✅ 方法一：命令行创建
kubectl create secret generic db-secret \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASSWORD=123456


查看：

kubectl get secret
kubectl describe secret db-secret


注意：describe 不会显示原文，只能看到 key 名称。
若要查看原始内容（仅限学习环境）：

kubectl get secret db-secret -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode

✅ 方法二：通过 YAML 定义

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

四、⚙️ 在 Pod 中使用 ConfigMap 和 Secret
🧩 方法一：作为环境变量注入

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


你会看到：

APP_COLOR=blue
APP_ENV=staging
DB_USER=admin
DB_PASSWORD=123456

🧩 方法二：挂载为文件（Volume 方式）

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
kubectl exec -it volume-demo -- ls /etc/config
kubectl exec -it volume-demo -- cat /etc/config/APP_COLOR


输出：

blue


查看 Secret：

kubectl exec -it volume-demo -- ls /etc/secret
kubectl exec -it volume-demo -- cat /etc/secret/username

五、🧠 ConfigMap 与 Secret 对比表
特性	ConfigMap	Secret
作用	保存非敏感配置	保存敏感信息
数据编码	明文	Base64 编码
类型	ConfigMap	Secret（Opaque / TLS / dockerconfigjson）
访问方式	环境变量或 Volume	环境变量或 Volume
安全性	一般	高（RBAC受控）
六、🧩 实战案例：为 Nginx 提供动态欢迎页

创建 welcome-config.yaml：

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


创建 nginx-cm-pod.yaml：

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


端口转发访问：

kubectl port-forward nginx-cm 8080:80


浏览器访问：

http://localhost:8080


✅ 你会看到由 ConfigMap 渲染的欢迎页面！

七、📘 今日总结

✅ 理解 ConfigMap 用于普通配置，Secret 用于敏感信息；

✅ 掌握两种创建方式（命令行与 YAML）；

✅ 学会两种挂载方式（环境变量与 Volume）；

✅ 通过实战体验了“配置即服务”的理念。

八、📗 今日任务清单
任务	命令	状态
创建 ConfigMap	kubectl apply -f configmap.yaml	✅
创建 Secret	kubectl apply -f secret.yaml	✅
注入环境变量	kubectl apply -f pod-env.yaml	✅
挂载 Volume	kubectl apply -f pod-volume.yaml	✅
动态 Nginx 页面	kubectl apply -f nginx-cm-pod.yaml	✅
记录学习笔记	~/k8s-learning/day6/day6.md	✍️