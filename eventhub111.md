# Azure 私有化日志导出与事件处理技术架构设计说明文档

**文档状态**：正式版（Final）  
**适用对象**：架构评审 / 安全与合规评审 / 平台建设 / 运维交付  
**适用场景**：金融、政企等高安全、强合规、零公网暴露环境  

---

## 1. 架构背景与设计目标

在企业级云平台建设过程中，日志与遥测数据往往包含大量运行状态、异常堆栈及业务上下文信息，其安全等级不低于核心业务数据本身。  
在金融、政企等强监管场景中，传统“公网采集 + 公网处理”的日志链路已难以满足内控、审计及数据主权要求。

本架构旨在构建一套：

- **零公网暴露（Zero Public Exposure）**
- **全链路私有网络传输**
- **可审计、可治理、可扩展**

的 **Azure 私有化日志导出与事件处理技术体系**。

---

## 2. 架构总体说明

整体架构基于以下核心能力构建：

- Azure Virtual Network（VNet）
- Private Endpoint + Private DNS Zone
- Log Analytics Data Export
- Event Hub（日志事件缓冲与解耦）
- Azure Function（私有化事件处理）
- Storage Account（安全落库与状态存储）

日志从产生、导出、处理到存储，**全程不经过公网**，所有通信均发生在 Azure 私有网络边界内。

---

## 3. 虚拟网络（VNet）与子网设计

### 3.1 VNet 基本参数

| 项目 | 说明 |
|----|----|
| VNet 类型 | Azure Virtual Network |
| 地址空间 | `10.x.x.0/16`（示例） |
| 网络模型 | Hub-Spoke 或独立业务 VNet |
| 公网访问 | 禁用（仅 Private Endpoint） |

VNet 是整个私有化架构的**网络边界与安全基础**，需预留充足地址空间以支持长期扩展。

---

### 3.2 子网划分与职责边界

#### Subnet-A：Outbound / Compute Subnet

| 项目 | 说明 |
|----|----|
| 用途 | Azure Function 出站访问 |
| 示例 CIDR | `10.x.1.0/24` |
| Delegation | `Microsoft.Web/serverFarms` |
| 是否允许 PE | ❌ 不允许 |

该子网仅用于 **Azure Function VNet Integration（出站）**，负责访问私有 Endpoint。

---

#### Subnet-B：Inbound Private Endpoint Subnet

| 项目 | 说明 |
|----|----|
| 用途 | 承载所有 Private Endpoint |
| 示例 CIDR | `10.x.2.0/24` |
| 是否部署计算 | ❌ 禁止 |
| NSG 建议 | 仅允许 VNet 内访问 |

该子网作为 **私有访问入口区**，集中承载 Storage、Event Hub 等 PaaS 的 Private Endpoint。

---

## 4. DNS 架构与解析关系（关键设计）

Private Endpoint 架构下，DNS 是系统可用性的关键依赖。

### 4.1 Private DNS Zone 列表

| 服务 | Private DNS Zone |
|----|----------------|
| Azure Function | `privatelink.azurewebsites.net` |
| Event Hub | `privatelink.servicebus.windows.net` |
| Storage Blob | `privatelink.blob.core.windows.net` |
| Storage Queue | `privatelink.queue.core.windows.net` |
| Storage Table | `privatelink.table.core.windows.net` |

### 4.2 DNS 与 VNet 的关系

- 所有 Private DNS Zone 必须 **Link 到业务 VNet**
- Hub-Spoke 架构下通常统一 Link 到 Hub VNet
- DNS Zone 与 VNet 绑定，而非与子网绑定

---

## 5. 数据流与网络路径说明

### Step 1：Log Analytics → Event Hub（日志导出）

- Log Analytics Workspace 配置 Data Export Rule
- 日志被持续推送至 Event Hub Namespace
- Event Hub 启用 Private Endpoint
- DNS 解析命中私有 IP（Service Bus Private Link）

---

### Step 2：Event Hub → Azure Function（事件处理）

- Azure Function 使用 **Event Hub Trigger**
- 通过独立 Consumer Group 进行消费隔离
- Function 通过 VNet Integration 出站访问 Event Hub Private Endpoint
- 全程私网通信

---

### Step 3：Azure Function → Storage Account（结果落库）

- Function 使用 Managed Identity 访问 Storage
- Blob / Queue / Table 均启用 Private Endpoint
- Storage Public Network Access = Disabled
- 访问权限通过 RBAC 精细控制

---

## 6. Azure Function 承载与运行模型选型

### 6.1 Azure Service Plan（Hosting Plan）类型对比

| Plan 类型 | 优点 | 缺点 | 是否推荐 |
|---------|------|------|--------|
| Consumption Plan | 成本低、无需容量规划 | 冷启动明显，不适合持续消费 | ❌ |
| **Premium Plan（EP）** | 支持 VNet / PE，预热实例，弹性伸缩 | 成本高于 Consumption | ✅ **首选** |
| Dedicated Plan | 无冷启动、成本可预测 | 弹性不足 | ⚠️ 次选 |
| Isolated Plan（ASE） | 最高隔离 | 成本极高、复杂 | ❌ |

**结论**：  
在本私有化事件处理架构中，**Premium Plan（Elastic Premium）为默认推荐方案**。

---

### 6.2 Azure Function 类型与触发方式

| 项目 | 选型 |
|----|----|
| Function 类型 | 事件驱动处理函数 |
| 触发器 | **Event Hub Trigger** |
| 运行语言 | Python / .NET（按团队栈） |
| 幂等性 | 必须 |
| 网络访问 | VNet Integration（Outbound） |

---

## 7. Storage Account 类型与配置选型

### 7.1 Storage Account 类型对比

| 类型 | 说明 | 是否推荐 |
|----|----|--------|
| **StorageV2** | 支持 Blob / Queue / Table，功能最全 | ✅ |
| StorageV1 | 早期类型 | ❌ |
| Blob Storage | 仅对象存储 | ⚠️ |
| File / Premium | 特殊场景 | ❌ |

---

### 7.2 冗余策略选择

| 冗余类型 | 适用建议 |
|-------|--------|
| LRS | 测试 / 非关键 |
| **ZRS** | ✅ 生产默认 |
| GRS / GZRS | 核心审计 / 灾备 |

---

### 7.3 安全配置要求

- Public Network Access：Disabled  
- 访问方式：Private Endpoint Only  
- 身份模型：Managed Identity + RBAC  
- 禁止长期使用 Account Key  
- 配置生命周期管理（Hot → Cool / Archive）

---

## 8. 安全、合规与运维要点

### 8.1 安全与合规特性

- 所有通信均为私有 IP
- 无公网 Endpoint 暴露
- 网络、身份、权限全可审计
- 满足金融与政企内控要求

---

### 8.2 常见工程风险

| 风险 | 影响 |
|----|----|
| DNS Zone 缺失 / 未 Link | 服务无法访问 |
| 子网职责混用 | 安全边界失效 |
| Consumer Group 误用 | 消费冲突或数据丢失 |

---

## 9. 架构总结

本架构通过：

- VNet 明确网络边界  
- 子网分层控制职责  
- Private Endpoint + DNS 实现私有化访问  
- Event Hub 实现日志解耦与缓冲  
- Azure Function 承担私有化处理核心  
- Storage Account 实现安全、合规落库  

在 **安全性、稳定性、扩展性与审计可追溯性** 之间取得了良好平衡，适合作为企业级标准架构在多项目中复用与推广。

---
