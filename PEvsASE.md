# Technical White Paper  
## Network Access Control Comparison

**Document ID:** ARCH-NET-SEC-2026-EN  
**Subject:** Comparative Analysis of Private Endpoint (PE) vs. ILB App Service Environment (ASE) for Azure Functions  
**Date:** February 13, 2026  
**Classification:** Internal – Architecture & Security  

---

# 1. Executive Summary

This white paper provides a comparative architectural analysis of two primary methods for securing Azure Function Apps within a private network:

1. Multi-tenant App Service with Private Endpoint (PE)  
2. Isolated Internal Load Balancer (ILB) App Service Environment (ASE)

The objective is to clarify:

- The architectural differences between the two approaches  
- The network access model of ILB ASE  
- Why certain NSG and Access Restriction configurations are required  
- Why these configurations do **not** imply public exposure  

It is important to emphasize:

> The current ILB ASE configuration does not enable public access.  
> It enforces layered internal authorization controls.

---

# 2. Architectural Comparison

| Feature | Private Endpoint (PE) | ILB ASE (Internal ASE) |
|----------|------------------------|--------------------------|
| Infrastructure Model | Multi-tenant (Shared) | Single-tenant (Dedicated / Isolated) |
| Public Entry Point | Logical (Toggle On/Off) | Physically Non-existent (Internal VIP only) |
| Public Network Access Toggle | Can be set to Disabled | Not Applicable (Inherently Private) |
| Traffic Path | Virtual tunnel via Private Link | Internal Load Balancer distribution |
| Trust Model | Implicit trust once PE is linked | Zero-Trust (Explicit per-layer authorization) |
| Network Control Complexity | Low (DNS-driven) | High (NSG + Routing + App-level rules) |

---

# 3. Detailed Traffic Flow & Access Logic

---

## 3.1 Solution A: Multi-tenant + Private Endpoint

This architecture can be described as:

> A secure tunnel carved into a public building.

### Mechanism

- When **Public Network Access = Disabled**, Azure blocks all traffic from the public internet.
- Traffic originating from within the VNet bypasses the public gateway.
- Access occurs via the Private Endpoint's Network Interface (NIC).
- DNS resolution directs traffic to the private IP.

### Security Implication

Because the Private Endpoint establishes a direct tunnel:

- The platform assumes network-level trust.
- Fewer application-layer restrictions are typically required.
- Access control is largely dependent on Private Link association and DNS integrity.

---

## 3.2 Solution B: ILB ASE (Current Environment)

An ILB ASE can be described as:

> A private data center built entirely inside your Virtual Network.

### Network Isolation Model

- No public IP address exists.
- No internet-facing endpoint exists.
- The "Public Network Access" toggle is irrelevant.
- The environment is physically disconnected from the internet.

---

### Multi-Layer Access Control ("Double-Lock" Model)

ILB ASE enforces security through two independent layers:

---

### 1️⃣ Network Layer – NSG (Subnet Level)

- All traffic must first pass the Subnet boundary.
- NSG rules must explicitly allow TCP 443.
- Without this rule, traffic is blocked before reaching the Function App.

This represents the:

> "Front Gate" security boundary.

---

### 2️⃣ Application Layer – Access Restrictions

Even after traffic enters the subnet:

- The Internal Load Balancer (ILB) requires explicit Access Restrictions.
- The Function App must allow specific IP ranges or subnets.
- Unauthorized internal IPs are rejected.

This represents the:

> Application-level fingerprint lock.

---

# 4. Technical Conclusion

The requirement to configure:

- NSG rules  
- Access Restrictions  

in an ILB ASE environment is not a sign of public exposure.

It is a byproduct of:

> A Zero-Trust security model with layered enforcement.

### Key Security Characteristics

- No public exposure at any point
- No shared ingress infrastructure
- Explicit authorization required at every layer
- Support for micro-segmentation

---

## Micro-Segmentation Capability

Unlike the Private Endpoint model:

- ILB ASE allows internal segmentation.
- Even internal users cannot access the Function unless:
  - Their IP range is explicitly authorized
  - Their subnet is permitted

This provides superior lateral movement control.

---

## Administrative Access Requirements

For deployment and administrative operations (e.g., `az deployment`, CI/CD pipelines):

- TCP protocol
- Port 443
- Access to the SCM (Kudu) endpoint

must be explicitly allowed in both:

- NSG rules
- Application Access Restrictions

---

# 5. Recommendation for Simplified Management

To reduce operational overhead caused by frequent NSG updates for individual developer IP addresses:

### Recommended Architecture Enhancement

Deploy an **Azure Application Gateway** as a centralized ingress control layer.

### Benefits

- Centralized IP whitelisting
- Reduced NSG rule churn
- Improved operational governance
- Enhanced monitoring and logging

### Implementation Pattern

1. Application Gateway becomes the single approved ingress.
2. Developer IPs are managed at the Gateway layer.
3. ILB ASE backend is configured to accept traffic only from the Gateway subnet.

This achieves:

- Simplified management  
- Strong network control  
- Preserved zero-public-exposure design  

---

# Final Statement

Both Private Endpoint and ILB ASE provide secure access models.

However:

- Private Endpoint relies on Private Link trust boundaries.
- ILB ASE enforces explicit authorization at multiple layers.

For environments requiring:

- Strong isolation
- Zero-trust enforcement
- Fine-grained micro-segmentation

ILB ASE represents the higher-security architectural model.
# 技术白皮书  
## 网络访问控制方案对比分析

**文档编号：** ARCH-NET-SEC-2026-CN  
**主题：** Azure Functions 的 Private Endpoint (PE) 与 ILB App Service Environment (ASE) 架构对比分析  
**日期：** 2026 年 2 月 13 日  
**密级：** 内部 – 架构与安全  

---

# 1. 执行摘要

本白皮书对两种主要的 Azure Function 私有化部署方案进行架构对比分析：

1. 多租户 App Service + Private Endpoint (PE)
2. 单租户 Internal Load Balancer (ILB) App Service Environment (ASE)

本文旨在说明：

- 两种架构的核心差异  
- ILB ASE 的网络访问模型  
- 为什么需要配置 NSG 与 Access Restrictions  
- 为什么这些配置不等同于“开启公网访问”  

需要特别强调：

> 当前 ILB ASE 环境并未暴露公网。  
> 所有配置均属于内部访问授权控制的一部分。

---

# 2. 架构对比

| 对比项 | Private Endpoint (PE) | ILB ASE（内部 ASE） |
|----------|------------------------|--------------------------|
| 基础设施模型 | 多租户（共享） | 单租户（专属 / 隔离） |
| 公网入口 | 逻辑存在（可开关） | 物理不存在（仅内部 VIP） |
| 公网访问开关 | 可设置为 Disabled | 不适用（天然私有） |
| 流量路径 | Private Link 虚拟隧道 | 内部负载均衡（ILB）分发 |
| 信任模型 | 建立 PE 后隐式信任 | 零信任（逐层显式授权） |
| 管理复杂度 | 较低（依赖 DNS） | 较高（NSG + 路由 + 应用层规则） |

---

# 3. 详细流量路径与访问逻辑

---

## 3.1 方案一：多租户 + Private Endpoint

该架构可以理解为：

> 在一栋公共大楼中开辟一条专属安全通道。

### 工作机制

- 当设置 **Public Network Access = Disabled** 时，公网流量会被 Azure 平台丢弃。
- 来自 VNet 内部的流量通过 Private Endpoint 的网络接口（NIC）直接进入。
- DNS 将域名解析为私有 IP 地址。
- 流量绕过公网网关。

### 安全特征

由于 Private Endpoint 建立了直接隧道：

- 平台默认建立一定程度的网络信任。
- 通常不需要复杂的应用层 IP 限制。
- 安全性依赖 Private Link 绑定与 DNS 配置的正确性。

---

## 3.2 方案二：ILB ASE（当前环境）

ILB ASE 可以理解为：

> 在你的虚拟网络内部构建的一座私有数据中心。

### 网络隔离特性

- 无公网 IP 地址
- 无互联网入口
- 不存在公网访问路径
- “Public Network Access” 开关在此环境下无意义

该环境在物理层面与公网隔离。

---

### 双层访问控制模型（“双重锁”）

ILB ASE 采用多层访问控制机制。

---

### 第一层：网络层（NSG 控制）

- 所有流量必须首先通过子网边界。
- 必须在 NSG 中明确允许 TCP 443。
- 若未配置该规则，流量会在子网层面被阻断。

该层相当于：

> 子网级“前门防线”。

---

### 第二层：应用层（Access Restrictions）

即使流量通过子网层：

- ILB 仍要求显式访问授权。
- 必须在 Function App 的 Access Restrictions 中允许特定 IP 或子网。
- 未授权 IP 即使在 VNet 内部也会被拒绝。

该层相当于：

> 应用级“指纹识别锁”。

---

# 4. 技术结论

在 ILB ASE 环境中必须配置：

- NSG 规则  
- Access Restrictions  

这并不代表开启公网访问，而是源于其：

> 零信任、多层授权的安全模型。

---

## 核心安全特征

- 全程无公网暴露  
- 无共享入口  
- 每一层均需显式授权  
- 支持微分段控制（Micro-segmentation）  

---

## 微分段能力

与 Private Endpoint 模式相比：

- ILB ASE 支持内部网络细粒度访问控制。
- 即使是内部用户，也必须被明确授权。
- 可防止横向移动风险。

---

## 运维与部署访问要求

对于部署与管理操作（例如 `az deployment`、CI/CD）：

必须允许：

- TCP 协议  
- 端口 443  
- 访问 SCM（Kudu）端点  

该规则需同时在：

- NSG  
- Access Restrictions  

中配置。

---

# 5. 简化管理的建议方案

为避免频繁手动更新开发人员 IP 的 NSG 规则，建议采用：

## 推荐增强架构

部署 **Azure Application Gateway** 作为统一入口。

---

## 优势

- 集中管理 IP 白名单  
- 减少 NSG 规则变更  
- 提升运维可控性  
- 增强访问审计能力  

---

## 实施模式

1. Application Gateway 作为唯一入口。
2. 在 Gateway 层集中维护开发 IP 白名单。
3. ILB ASE 仅允许来自 Gateway 子网的流量。

实现效果：

- 简化管理  
- 强化网络控制  
- 保持零公网暴露设计  

---

# 最终说明

Private Endpoint 与 ILB ASE 均可实现私有化访问。

但两者的安全模型不同：

- Private Endpoint 依赖 Private Link 信任边界。
- ILB ASE 采用逐层显式授权的零信任模型。

对于要求：

- 强隔离  
- 严格访问控制  
- 内部微分段  

的环境，ILB ASE 提供更高级别的安全能力。
