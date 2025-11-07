Day 1：理解云原生与 Kubernetes 背景
🎯 学习目标

理解 Kubernetes 是什么，它解决了什么问题

理解“云原生（Cloud Native）”的核心理念

搭建学习环境的基础认知，为后续实操做准备

📖 理论学习
一、什么是 Kubernetes

Kubernetes（简称 K8s）是由 Google 开发、后捐赠给 CNCF 的容器编排系统，用于自动化应用的部署、伸缩、负载均衡和管理。
简单来说，它是“容器世界的操作系统”。

K8s 主要解决的问题包括：

容器调度：自动选择合适节点运行容器；

服务发现与负载均衡：通过 Service 自动暴露应用；

自愈机制：Pod 异常会被自动替换；

弹性伸缩：根据负载自动扩缩容；

声明式管理：通过 YAML 文件定义系统状态，K8s 自动确保实际状态与目标状态一致。

二、云原生（Cloud Native）理念

Cloud Native 是一种利用云计算优势的应用设计方法，核心是：

可移植、可扩展、自动化、可观测。

其四大支柱包括：

容器化（Containers）：应用与依赖打包在一起；

微服务化（Microservices）：应用拆分为小型服务；

动态管理（Dynamic Orchestration）：K8s 等系统自动调度；

声明式 API（Declarative API）：以配置文件声明系统状态。

📚 推荐阅读：

CNCF 云原生定义：https://github.com/cncf/toc/blob/main/DEFINITION.md

Kubernetes 官方简介：https://kubernetes.io/learn/

三、Kubernetes 架构初识

Kubernetes 由两部分组成：

控制平面（Control Plane）：负责整个集群的决策和调度。
包括：

kube-apiserver（API接口）

etcd（集群状态存储）

kube-scheduler（调度器）

kube-controller-manager（控制器管理器）

数据平面（Node）：运行用户容器的实际节点。
包括：

kubelet（与API Server通信）

kube-proxy（网络代理）

容器运行时（如 containerd 或 Docker）

📘 图示：

+---------------- Control Plane ----------------+
|  API Server | Scheduler | Controller | etcd  |
+------------------------------------------------+
|                  Node(s)                      |
| kubelet | kube-proxy | container runtime      |
| Pods: [app, sidecar, monitor...]              |
+------------------------------------------------+

🧰 实操任务
任务 1：确认 macOS 系统环境

在终端运行：

sw_vers


确认系统版本（建议 macOS 12+）。

任务 2：安装 Homebrew（若未安装）

Homebrew 是 macOS 的包管理器，用于安装后续所有工具。

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


验证安装成功：

brew -v

任务 3：创建学习工作区

在你的主目录下新建一个文件夹，用于存放所有 K8s 学习资料。

mkdir -p ~/k8s-learning/day1
cd ~/k8s-learning/day1

任务 4：记录学习笔记

推荐用 Markdown 记录你的学习日志（例如用 VSCode 或 Obsidian 打开 day1.md）：

# Day 1 学习笔记

## 今日收获
- 理解了 Kubernetes 的定位与作用
- 了解云原生理念与四大支柱
- 熟悉 K8s 控制平面与数据平面架构

✅ 今日成果

✅ 理解云原生与 Kubernetes 的关系

✅ 搭建好 mac 环境与学习目录

✅ 明确后续安装目标（Docker、kubectl、Minikube）