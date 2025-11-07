一、Kubernetes 架构总体概览

Kubernetes 是一个分布式系统，它的核心设计理念是“声明式状态管理（Declarative State Management）”。
用户告诉它“我要什么”，K8s 自动去维持系统的“期望状态（Desired State）”。

🔹 架构层级

Kubernetes 架构分为两大部分：

层级	作用	组成组件
控制平面（Control Plane）	管理和调度整个集群，确保系统状态符合用户定义	API Server、Scheduler、Controller Manager、etcd
数据平面（Worker Node）	实际运行容器化应用的节点	kubelet、kube-proxy、容器运行时（containerd / Docker）
🧭 二、控制平面（Control Plane）

控制平面是整个 Kubernetes 的“大脑”，负责决策、调度、状态存储和集群管理。

1. kube-apiserver（核心中枢）

作用：整个系统的唯一入口，负责与所有组件通信。

功能：

接收 kubectl 命令请求（REST API）

验证身份（Authentication）与权限（Authorization）

将请求存储到 etcd

将结果返回给客户端

本质：是一个 HTTP REST 接口服务器。
它是“控制平面”与“数据平面”的桥梁。

📘 示例：

kubectl create deployment nginx --image=nginx


该命令会发送一个 HTTP 请求到 kube-apiserver，告诉它要创建一个 Deployment 对象。

2. etcd（分布式键值数据库）

作用：存储整个集群的所有状态。

类型：分布式一致性存储系统（Raft 算法）

存储内容：

所有 K8s 对象（Pod、Service、ConfigMap…）

集群元数据（Node 信息、资源配额等）

特性：

高一致性（Strong Consistency）

支持快照与备份恢复（Snapshot & Restore）

🧠 小贴士：
Kubernetes 的“声明式配置”依赖 etcd。
用户定义的“期望状态（Desired State）”会存入 etcd，控制器通过它不断对比“实际状态（Current State）”。

3. kube-scheduler（调度器）

作用：决定 Pod 运行在哪个节点上。

工作原理：

监听 API Server 中的未绑定 Pod；

计算所有可用节点的资源与约束；

根据调度算法（例如亲和性/资源负载）选择最佳节点；

将调度结果写回 API Server。

🧩 调度策略：

资源维度：CPU、内存是否足够；

约束维度：节点选择规则（NodeSelector、Affinity、Taint）；

优化维度：负载均衡、优先级、延迟。

4. kube-controller-manager（控制器管理器）

作用：维持系统“期望状态”与“实际状态”的一致性。

机制：基于“控制循环（Control Loop）”。

内部包含多个控制器（Controller）：

ReplicationController：确保副本数量正确；

NodeController：监控节点状态；

EndpointController：维护 Service 与 Pod 的映射；

JobController / CronJobController：管理批处理任务；

ServiceAccountController：管理认证凭证。

📘 控制循环示意：

while True:
    desired_state = etcd.get('pod_replicas=3')
    current_state = get_running_pods()
    if current_state < desired_state:
        create_new_pod()

⚙️ 三、数据平面（Worker Node）

数据平面由若干个 Node 节点 组成，是运行实际应用的地方。

1. kubelet

作用：节点代理，负责“让节点听从命令”。

功能：

监听 API Server 的指令；

创建、启动、监控、销毁容器；

上报节点状态；

确保 Pod 在节点上持续运行。

交互：

从 API Server 获取 PodSpec；

通过容器运行时（containerd/Docker）执行实际操作。

2. kube-proxy

作用：实现 Kubernetes 的网络代理与负载均衡。

功能：

管理 Service 与 Pod 的网络连接；

支持三种代理模式：userspace、iptables、ipvs；

确保 Service 的虚拟 IP（ClusterIP）可以路由到正确的 Pod。

📘 例如：
访问一个 Service（ClusterIP = 10.96.0.5），kube-proxy 会自动将流量分发到实际的 Pod IP 列表中。

3. 容器运行时（Container Runtime）

作用：真正负责运行容器的引擎。

常见类型：

containerd（K8s默认）

CRI-O

Docker Engine（早期使用）

📘 它负责：

拉取镜像；

创建容器；

管理容器生命周期；

向 kubelet 报告容器状态。

🔄 四、Kubernetes 工作流程

当你运行一条命令时：

kubectl create deployment nginx --image=nginx


完整流程如下：

kubectl → kube-apiserver → etcd
              ↓
      kube-scheduler  ←→  kube-controller-manager
              ↓
          kubelet → container runtime → Pod 运行
              ↓
          kube-proxy → Service 网络访问


数据流简图：

+---------------- Control Plane ----------------+
|  API Server <-> etcd <-> Controller Manager   |
|        |                                      |
|        +--> Scheduler -> Node (kubelet)       |
+-----------------------------------------------+
                   ↓
+---------------- Worker Nodes -----------------+
| kubelet + kube-proxy + container runtime      |
| Pods/Containers/Services 实际运行             |
+-----------------------------------------------+

🔐 五、架构特性总结
特性	描述
声明式管理	用户声明期望状态，系统自动维持
松耦合组件	每个组件可独立扩展或替换
控制循环（Reconciliation Loop）	持续对比 Desired State 与 Current State
可扩展性强	CRD + Operator 模式扩展自定义逻辑
高可用与容错	多控制面副本 + etcd 集群
插件化	网络（CNI）、存储（CSI）、运行时（CRI）可插拔
🧩 六、建议实践

你可以在本地（mac）快速体验这一架构的缩小版：

brew install minikube
minikube start --driver=docker
kubectl get nodes
kubectl get all -A


然后访问 Dashboard：

minikube dashboard


就能看到控制平面（API Server、Controller）与数据平面（Pods）的运行情况。
一、整体类比：K8s 是一个「智能工厂」

想象一下：
你是一家“应用工厂”的老板，你只要告诉工厂——

“我想要 3 台机器（Pod）一直在运转，如果有坏的，立刻换新的。”

Kubernetes 就是那个负责帮你实现一切自动化的“智能工厂管理系统”。
你只要下命令（声明“我要什么”），它就会自己：

找工人（调度节点）；

买原料（拉镜像）；

开机器（启动容器）；

检查生产线（监控 Pod）；

修机器（自动重启失败的 Pod）。

🧠 二、控制平面（老板和管理层）

控制平面就是工厂的管理中枢，它由四个关键角色组成。

角色	类比	职责
API Server	总经理办公室	负责接收命令、分配任务。你所有指令都要通过它。
etcd	档案室 / 数据库	负责保存所有资料：生产计划、机器状态、员工名单。
Scheduler	调度主管	负责决定哪个工人干哪个活——Pod 应该放在哪台机器上运行。
Controller Manager	质量监督部	负责不断检查实际情况和计划是否一致，不一致就立刻修正。

📘 类比举例：
你（用户）通过 kubectl 提交命令 → 总经理(API Server) 接到任务 → 调度主管(Scheduler) 分配工作 → 质量监督部(Controller) 检查执行 → 档案室(etcd) 记录所有变化。

⚙️ 三、数据平面（工人和生产线）

数据平面就是真正干活的工人和生产车间，由很多“节点（Node）”组成。

组件	类比	职责
kubelet	车间主管	接收总部命令，在机器上安排生产（运行容器），并汇报进度。
container runtime	机械臂	实际执行任务：启动、停止容器（比如 Docker 或 containerd）。
kube-proxy	网络管理员	打通车间之间的网络，确保不同机器能相互通信。

📘 举例：
总部说“启动一个 Nginx 服务”，kubelet 就在工人机器上启动一个容器，containerd 负责执行，kube-proxy 负责让外部能访问它。

🔁 四、工厂的运作流程（声明式管理）

整个 Kubernetes 就像一个永不休息的工厂管理循环。

你提需求（Desired State）
比如告诉它：“我要有 3 个 Nginx 容器在跑。”

系统记录（etcd）
需求被记录在数据库里。

系统执行（Scheduler + Controller）
它发现当前只有 1 个容器，于是创建 2 个新的。

持续检查（Reconcile Loop）
有容器挂掉？Controller 发现后马上重新补一个。

🌀 这叫 “控制循环（Control Loop）”：
系统一直在“对比期望状态 vs 实际状态”，
自动调整，直到两者完全一致。

🕸 五、形象图解（简化版）
         +---------------------------------------+
         |             控制平面（总部）            |
         |---------------------------------------|
         | API Server  - 接收命令、分配任务       |
         | etcd        - 保存集群状态            |
         | Scheduler   - 给 Pod 找机器            |
         | Controller  - 监控 & 修复差异          |
         +---------------------------------------+
                          ↓ 指令
         +---------------------------------------+
         |             数据平面（工厂车间）        |
         |---------------------------------------|
         | Node1: kubelet, kube-proxy, containers |
         | Node2: kubelet, kube-proxy, containers |
         | Node3: kubelet, kube-proxy, containers |
         +---------------------------------------+
                          ↑ 状态上报

🧩 六、Kubernetes 的核心特性，用生活类比解释
特性	通俗理解
声明式管理	你只需要说“我想要什么”，系统自动帮你做到。
自愈（Self-Healing）	容器挂了自动重启，就像机器坏了自动换一台。
滚动更新（Rolling Update）	系统逐台换新，不停工。
自动扩缩容（Autoscaling）	负载高时加人手，负载低时减人手。
服务发现（Service Discovery）	不用记 IP，K8s 帮你自动打电话找对人。
负载均衡（Load Balancing）	多个 Pod 平均分摊访问压力。
🌟 七、最精炼的一句话总结

Kubernetes 就是一套让“机器自己管机器”的自动化系统，
它像一座无人化工厂：你只要写好计划书（YAML 文件），
它就能自动调度、运行、监控、修复、扩容一切应用。