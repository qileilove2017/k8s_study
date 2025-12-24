这是你前 20 天 Kubernetes 学习的阶段性综合实战。
我们将把你学过的 Deployment / Service / ConfigMap / Secret / PVC / Ingress / RBAC / Debug 整合到一个真正的三层 Web 应用中。

你将部署一个完整可访问的应用架构：

Client → Ingress → Nginx (Frontend)
                     ↓
                Flask API (Backend)
                     ↓
                  MySQL DB


✔ 全容器化
✔ K8s 服务间通信
✔ 持久化数据库
✔ 环境变量注入
✔ 外部域名访问

让你从“只会部署 Pod” → “能运维真正的业务级应用”。

☸️ Day 20：复盘 & 实战部署三层应用（Nginx + Flask + MySQL）
🎯 今日目标

回顾前 20 天知识

建立生产级三层 Web 架构

掌握前端/后端/数据库的组合部署

使用 Service + PVC + Deployment + Ingress 组合

使用 ConfigMap + Secret 管理配置

完成一次“从 0 到可访问”的系统架设

一、📦 MySQL 数据库（Stateful + PVC）
Step 1：创建 MySQL root 密码（Secret）

mysql-secret.yaml

apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
data:
  password: bXlzcWwxMjM=   # mysql123 (base64)


应用：

kubectl apply -f mysql-secret.yaml

Step 2：创建 MySQL PVC（持久化）

mysql-pvc.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi


应用：

kubectl apply -f mysql-pvc.yaml

Step 3：部署 MySQL

mysql-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc


Service：

apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
  - port: 3306
  selector:
    app: mysql


应用：

kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml

二、🔥 Flask 后端 API

功能：
访问 /api 时返回 MySQL 里的时间戳（测试 DB 通信）

示例 Dockerfile（可提前 build）：

FROM python:3.10-slim
RUN pip install flask mysql-connector-python
COPY app.py /app/app.py
CMD ["python", "/app/app.py"]


app.py：

from flask import Flask
import mysql.connector
import os

app = Flask(__name__)

@app.route("/api")
def api():
    db = mysql.connector.connect(
        host=os.environ["MYSQL_HOST"],
        user="root",
        password=os.environ["MYSQL_PASSWORD"]
    )
    cursor = db.cursor()
    cursor.execute("SELECT NOW()")
    result = cursor.fetchone()
    return {"message": "Hello from Flask!", "mysql_time": str(result[0])}

后端 Deployment

flask-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask
  template:
    metadata:
      labels:
        app: flask
    spec:
      containers:
      - name: flask
        image: yourrepo/flask-demo:latest
        ports:
        - containerPort: 5000
        env:
        - name: MYSQL_HOST
          value: mysql
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password


Service：

apiVersion: v1
kind: Service
metadata:
  name: flask
spec:
  ports:
  - port: 5000
  selector:
    app: flask


应用：

kubectl apply -f flask-deployment.yaml
kubectl apply -f flask-service.yaml

三、🌐 Nginx 作为前端（反向代理到 Flask）
Step 1：Nginx 配置（ConfigMap）

nginx-config.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  default.conf: |
    server {
      listen 80;
      location / {
        proxy_pass http://flask:5000;
      }
    }


应用：

kubectl apply -f nginx-config.yaml

Step 2：Nginx Deployment

nginx-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config


Service：

apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  ports:
  - port: 80
  selector:
    app: nginx


应用：

kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

四、🚪 Ingress：将前端暴露到外部

你在 Day 18 已安装 ingress-nginx，可直接使用。

ingress-web.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: demo.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80


应用：

kubectl apply -f ingress-web.yaml


修改 /etc/hosts：

<node-ip>   demo.local


访问：

http://demo.local/


你将看到：

{
  "message": "Hello from Flask!",
  "mysql_time": "2025-01-01 12:00:00"
}


🌟 完整三层应用上线成功！

五、📘 今日复盘（非常关键）

你今天整合了：

知识	哪里用到
Deployment	Nginx / Flask / MySQL
Service（ClusterIP）	三层应用内部的通信
PVC	MySQL 持久化
Secret	MySQL 密码
ConfigMap	Nginx 配置
Ingress	对外流量入口
Logs / Describe	调试 Flask / MySQL 启动
网络模型	前端 → 后端 → DB

这是前 20 天全部知识点的“期中考试”。
你现在已经可以部署一个可以对外提供服务的真正应用。

六、📗 今日任务清单
任务	文件	状态
创建 Secret	mysql-secret.yaml	⬜
创建 PVC	mysql-pvc.yaml	⬜
部署 MySQL	mysql-deployment.yaml	⬜
部署 Flask API	flask-deployment.yaml	⬜
配置 Nginx	nginx-config.yaml	⬜
部署 Nginx	nginx-deployment.yaml	⬜
创建 Ingress	ingress-web.yaml	⬜
访问 demo.local	浏览器 / curl	⬜
写总结	day20-three-tier.md	✍️
七、📘 今日总结

你已经完成了 Kubernetes 中最核心的技能之一：
部署一套真实可工作的三层架构应用。

你现在具备：

构建应用

配置网络

管理状态

配置密钥与配置项

实现外部访问

调试服务

从今天起，你已经可以独立部署企业内部系统。