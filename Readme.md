# 🌊 Kubernetes 60天系统学习计划（mac 环境）

## 阶段1：基础与环境准备（Day 1–10）

| 天数 | 主题 | 学习目标 | 实战任务 |
|------|------|-----------|-----------|
| Day 1 | 理解云原生与K8s背景 | 理解Kubernetes的作用与生态 | 阅读官方概览：https://kubernetes.io/learn/ |
| Day 2 | 安装Docker Desktop & CLI | 搭建Docker环境 | 安装 Docker Desktop for Mac；运行 `docker run hello-world` |
| Day 3 | 安装kubectl | 掌握kubectl基本操作 | `brew install kubectl`，执行 `kubectl version` |
| Day 4 | 安装Minikube | 学会启动本地K8s集群 | `brew install minikube`，`minikube start --driver=docker` |
| Day 5 | 探索K8s Dashboard | 学会使用Dashboard管理资源 | 启动dashboard：`minikube dashboard` |
| Day 6 | 了解Pod与Manifest文件 | 掌握YAML结构与Pod定义 | 创建`pod.yaml`：运行 `kubectl apply -f pod.yaml` |
| Day 7 | 理解ReplicaSet与Deployment | 学会无状态应用部署 | 创建一个`nginx-deployment.yaml` |
| Day 8 | 理解Service（ClusterIP / NodePort） | 学会暴露服务 | 创建`service.yaml`访问nginx |
| Day 9 | 理解Namespace与Label | 学会资源分组与选择 | 创建自定义namespace与label选择器 |
| Day 10 | 复习与整理 | 梳理常用命令 | 整理一份命令速查表：`kubectl get/apply/describe/logs` |

## 阶段2：核心功能进阶（Day 11–25）

| 天数 | 主题 | 学习目标 | 实战任务 |
|------|------|-----------|-----------|
| Day 11 | ConfigMap 与 Secret | 学习配置管理 | 创建ConfigMap与Secret并挂载到Pod |
| Day 12 | Volume与PersistentVolume | 理解存储机制 | 创建PVC绑定到Pod中持久化数据 |
| Day 13 | StatefulSet | 理解有状态服务 | 部署Redis StatefulSet |
| Day 14 | DaemonSet | 学习节点守护服务 | 部署Node Exporter |
| Day 15 | Job 与 CronJob | 定时任务与批处理 | 创建备份任务 `CronJob` |
| Day 16 | 探索RBAC权限控制 | 理解Role、ClusterRole | 创建`ServiceAccount`并限制访问 |
| Day 17 | 探索K8s网络模型 | 理解Pod通信与Service DNS | 使用`busybox`验证Pod间通信 |
| Day 18 | Ingress 控制器 | 学会使用Nginx Ingress | 部署`ingress-nginx`并访问外部服务 |
| Day 19 | 探索K8s事件与日志 | 学会调试K8s问题 | 使用`kubectl describe`与`logs`分析错误 |
| Day 20 | 复盘 & 部署一个三层应用 | 整合前端+后端+DB | 部署Nginx + Flask + MySQL |
| Day 21–22 | 探索Helm包管理 | 安装Helm并使用Chart部署 | `brew install helm`，部署`helm install mynginx bitnami/nginx` |
| Day 23–24 | 探索Prometheus监控 | 学习监控与告警机制 | 通过Helm部署Prometheus |
| Day 25 | 部署Grafana | 可视化监控 | 连接Prometheus数据源，创建Dashboard |

## 阶段3：生产级应用与CI/CD（Day 26–45）

| 天数 | 主题 | 学习目标 | 实战任务 |
|------|------|-----------|-----------|
| Day 26 | 探索kubeconfig与上下文管理 | 学会多集群切换 | 创建多个context进行切换 |
| Day 27 | 探索资源限制与HPA | 学会弹性伸缩 | 部署HPA自动扩缩容 |
| Day 28 | 探索Pod亲和性与反亲和性 | 学习调度策略 | 设计NodeAffinity规则 |
| Day 29–30 | 探索Taint与Toleration | 学会节点污点控制 | 设置污点并配置Pod容忍 |
| Day 31–32 | 探索Pod Security与NetworkPolicy | 提升安全性 | 编写NetworkPolicy限制通信 |
| Day 33–34 | 探索K8s日志收集 | 部署ELK / Loki | 使用Helm部署Loki Stack |
| Day 35–36 | 探索CI/CD概念 | 理解DevOps在K8s中的应用 | 学习GitOps与ArgoCD原理 |
| Day 37–38 | 实践GitOps部署 | ArgoCD或Flux | 在minikube部署ArgoCD |
| Day 39–40 | 探索Terraform管理K8s资源 | 学习IaC | 使用Terraform创建Deployment与Service |
| Day 41–42 | 探索Operator概念 | 理解K8s可扩展架构 | 阅读Operator SDK示例 |
| Day 43–44 | 编写自定义Controller（Go或Python） | 学习控制循环机制 | 实现简单的ConfigMap Watcher |
| Day 45 | 阶段总结 | 复习与笔记整理 | 输出阶段性总结文档 |

## 阶段4：生产化部署与高可用架构（Day 46–60）

| 天数 | 主题 | 学习目标 | 实战任务 |
|------|------|-----------|-----------|
| Day 46–47 | 多节点K8s集群搭建（Kind / k3d） | 理解集群拓扑结构 | 搭建3节点Kind集群 |
| Day 48–49 | 探索高可用与ETCD | 理解控制面高可用 | 学习ETCD备份与恢复 |
| Day 50–52 | 探索Service Mesh（Istio） | 掌握流量管理与A/B测试 | 部署Istio并实践灰度发布 |
| Day 53–54 | 探索分布式追踪（Jaeger） | 学习分布式链路分析 | 部署Jaeger连接微服务 |
| Day 55–56 | 探索资源优化与自动扩缩容 | 学习Cluster Autoscaler | 模拟自动扩容节点 |
| Day 57–58 | 故障注入与混沌测试 | 学习系统韧性 | 安装Chaos Mesh并测试 |
| Day 59 | 综合项目部署 | 构建完整电商应用部署 | 使用Helm一键部署完整系统 |
| Day 60 | 总结与展望 | 输出技术总结报告 | 整理知识图谱与实践心得 |

---

📘 **推荐资料与工具**
- 官方文档：https://kubernetes.io/docs/
- 实战书籍：《Kubernetes in Action》《Cloud Native DevOps with Kubernetes》
- 在线课程：Kubernetes by Google (Coursera)
- 工具推荐：Lens、kubectx + kubens、K9s、kube-forwarder
