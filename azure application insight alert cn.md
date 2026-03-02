# Azure Monitor 日志告警架构设计说明文档

**文档类型：** 技术架构设计文档  
**适用范围：** 企业级日志告警体系  
**适用环境：** 强合规 / 私网部署场景  

---

# 1. 架构目标

本架构旨在构建一套具备以下特性的日志告警体系：

- 支持 Infrastructure-as-Code（IaC）
- 满足审计与合规要求
- 可横向扩展复用
- 判断逻辑与通知逻辑解耦
- 适用于企业内网与高安全环境

### 核心技术栈

- Terraform  
- Azure Monitor  
- Log Analytics Workspace  
- Kusto Query Language（KQL）  
- Azure Monitor Action Group  

---

# 2. 架构分层模型

本架构采用三层模型设计：

| 分层 | 组件 | 职责 |
|------|------|------|
| 控制面（Control Plane） | Azure Monitor API | 存储与管理告警规则 |
| 执行面（Runtime Plane） | Azure Alert Engine | 调度与执行判断逻辑 |
| 数据面（Data Plane） | Log Analytics Workspace | 存储日志并执行查询 |

通过分层设计，实现职责隔离与系统稳定性。

---

# 3. 架构组件详解

---

## 3.1 Terraform（基础设施声明层）

Terraform 负责：

- 创建 Log Analytics Workspace  
- 创建 Alert Rule  
- 创建 Action Group  
- 管理阈值与 KQL 文件引用  

Terraform 不负责：

- 执行 KQL 查询  
- 执行告警逻辑  
- 控制告警状态  

Terraform 的作用是：

> 向 Azure Monitor 注册告警规则定义。

---

## 3.2 Azure Monitor（控制面）

Azure Monitor 控制面负责：

- 接收告警规则定义  
- 存储规则  
- 管理规则生命周期  
- 启用/禁用规则  

### 特点

- 平台级服务  
- 默认在所有订阅中启用  
- 无需单独部署  

---

## 3.3 Alert Engine（执行面）

Alert Engine 是告警体系的核心执行单元。

### 核心职责

- 按 `evaluation_frequency` 调度  
- 执行 KQL 查询  
- 计算 `metric_measure_column`  
- 判断 `operator + threshold`  
- 应用 `failing_periods` 逻辑  
- 管理告警状态（Fired / Resolved）  

### 架构特性

- 运行在 Azure 平台内部  
- 不占用客户资源  
- 不部署在客户 VNet 内  
- 不需要 Private Endpoint  

Alert Engine 通过平台内部安全通道访问 Log Analytics。

---

## 3.4 Log Analytics Workspace（数据层）

Workspace 负责：

- 存储 Application Insights 遥测数据  
- 执行 KQL 查询  
- 向 Alert Engine 提供查询结果  

### 常用核心表

- `requests`
- `dependencies`
- `exceptions`
- `traces`

### 企业级设计建议

- 采用统一或分层 Workspace 策略  
- 使用 `cloud_RoleName` 进行逻辑隔离  
- 启用日志保留与访问控制策略  

---

## 3.5 Action Group（响应层）

Action Group 负责：

- 邮件通知  
- Teams 通知  
- Webhook 调用  
- ITSM 工单创建  
- Azure Function 自动化执行  

### 核心设计原则

告警规则与响应机制完全解耦。

- 一个 Action Group 可被多个 Alert 复用  
- 告警判断逻辑与通知策略独立演进  

---

# 4. 告警运行流程

在每个 `evaluation_frequency` 周期内：

1. Alert Engine 启动调度  
2. 执行 KQL 查询  
3. 生成结果集  
4. 提取 `metric_measure_column`  
5. 与 `threshold` 进行比较  
6. 应用 `failing_periods` 判断逻辑  
7. 满足条件则进入 **Fired 状态**  
8. 触发关联的 Action Group  

---

# 5. 网络与安全设计说明

## 5.1 Private Endpoint 需求分析

| 组件 | 是否需要 Private Endpoint |
|------|----------------------------|
| Alert Engine | 不需要 |
| Azure Monitor 控制面 | 不需要 |
| Log Analytics Workspace | 企业内网建议使用 |
| Action Group Webhook | 若目标为内网 API，则需要 |

### 原因说明

Alert Engine 运行在 Azure 平台内部，通过内部服务通道访问 Log Analytics。

因此：

- 不需要部署在 VNet 中  
- 不需要 Private Endpoint  
- 不存在公网入站暴露问题  

---

# 6. 架构优势

---

## 6.1 判断与通知解耦

- Alert Rule 仅负责判断  
- Action Group 仅负责通知  

提高可维护性与可扩展性。

---

## 6.2 可代码化管理

- 所有规则通过 Terraform 管理  
- 支持版本控制  
- 满足审计与合规要求  

---

## 6.3 可横向扩展

- 新增服务仅需新增 KQL  
- 可复用现有 Action Group  
- 无需变更整体架构  

---

## 6.4 成本可控

- `evaluation_frequency` 可配置  
- 时间窗口可控制  
- 查询范围可限制  

实现精细化成本管理。

---

# 7. 设计最佳实践

---

## 7.1 统一规范要求

所有 KQL 必须：

- 包含明确时间窗口  
- 包含 `cloud_RoleName` 过滤  
- 默认采用 `failing_periods = 3 of 2` 推荐模式  

---

## 7.2 告警分级策略

| 严重级别 | 用途说明 |
|-----------|----------|
| 0 | 全站不可用 |
| 1 | 核心 API 故障 |
| 2 | 功能异常 |
| 3 | 性能下降 |
| 4 | 观测类或信息类 |

---

# 8. 架构总结

本架构核心思想为：

- Terraform 定义规则  
- Azure Monitor 存储规则  
- Alert Engine 执行规则  
- Log Analytics 提供数据  
- Action Group 负责响应  

该体系：

- 不需要单独创建 Azure Monitor  
- 不需要部署 Alert Engine  
- 仅需定义规则与数据源  

最终实现：

- 企业级可扩展  
- 合规可审计  
- 平台托管高可用  
- 解耦式设计  

的日志告警架构体系。