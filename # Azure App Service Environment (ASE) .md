# Azure App Service Environment (ASE) 与 Azure Function 架构说明

**文档类型：** 架构说明文档  
**适用环境：** 生产环境（强监管 / 高安全要求场景）  
**文档目的：** 简要说明 ASE 架构特点、Azure Function 部署模式及费用结构，辅助技术选型决策。

---

## 1. 什么是 Azure App Service Environment（ASE）？

Azure App Service Environment（ASE）是部署在客户自有虚拟网络（VNet）中的**单租户 App Service 环境**。

与标准多租户 App Service 不同，ASE 具备以下特点：

- 专属计算资源（不与其他客户共享）  
- 部署在指定的私有子网中  
- 支持内部负载均衡（ILB）模式  
- 可完全控制入站与出站网络流量  

简单理解：

> 标准 App Service 是共享平台，  
> ASE 是运行在自己网络边界内的专属平台。

ASE 通常用于强监管或对安全隔离要求极高的生产环境。

---

## 2. Azure Function 在 ASE 中的运行方式

当 Azure Function 部署在 ASE 中时：

- 必须使用 **Isolated / Dedicated 模式**
- 不支持 Consumption 计划
- 不依赖共享前端入口
- 可以实现完全无公网暴露

### 核心特点

- 完整 VNet 集成  
- 支持仅内网访问  
- 可与 Private Endpoint 无缝集成  
- 与其他租户完全隔离  

因此，ASE 适用于要求严格内网访问或合规隔离的系统。

---

## 3. ASE 与 Premium Plan 的核心区别

尽管 Premium Plan 和 ASE 都支持企业级工作负载，但在隔离级别与成本方面存在明显差异。

| 对比维度 | Premium Plan | ASE |
|------------|--------------|------|
| 租户模式 | 多租户 | 单租户 |
| 网络隔离级别 | 中等 | 极高 |
| 公网暴露 | 共享前端 | 可完全私有 |
| 成本水平 | 中等 | 高 |
| 典型场景 | 企业级应用 | 金融 / 强监管核心系统 |

### 总结

> Premium Plan 属于企业级，  
> ASE 属于强合规级。

如果业务明确要求单租户级别隔离，则 ASE 更为适合。

---

## 4. ASE 费用结构说明

ASE 的费用模型与 Premium Plan 有明显不同。

### 4.1 固定基础设施费用

ASE 包含固定基础费用：

- 按小时计费  
- 即使没有运行应用也会产生费用  
- 通常每月数千美元起  

该费用用于覆盖专属平台基础设施成本。

---

### 4.2 Worker 实例费用

每个 Worker 实例单独计费。

常见规格包括：

- I1v2 —— 小规模负载  
- I2v2 —— 中等规模负载  
- I3v2 —— 高性能负载  

实例数量越多，总成本线性增加。

---

### 4.3 相关附加成本

除 ASE 本身外，还需考虑：

- Log Analytics 日志摄入费用  
- Event Hub 吞吐费用  
- Storage 读写费用  
- Private Endpoint  
- NAT Gateway 或 Firewall  

典型生产环境下：

> ASE 月成本通常在数千至上万美元区间，具体取决于规模与区域。

---

## 5. 什么时候应该使用 ASE？

### 建议使用场景

- 合规要求必须单租户部署  
- 禁止任何形式公网暴露  
- 必须实现严格内部访问控制  
- 金融或政府核心系统  

### 不建议使用场景

- 成本敏感型系统  
- 隔离要求中等  
- Premium Plan + Private Endpoint 已满足需求  
- 流量规模较小  

在大多数企业级场景中：

> Premium Plan + Private Endpoint 已可满足私有化与安全要求，且成本显著更低。

---

## 最终建议

ASE 提供 App Service 体系内最高级别的隔离能力，但其成本明显高于其他方案。

是否选择 ASE，应基于以下因素综合判断：

- 合规等级  
- 安全要求  
- 预算规模  
- 工作负载规模与增长预期  

如果主要目标是实现私有网络访问，而非强制单租户隔离：

> Premium Plan 通常是更具性价比的选择。
