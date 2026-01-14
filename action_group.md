## Azure Action Group 技术设计文档

**组件类型**：告警响应与自动化编排中枢  
**适用架构**：Azure 私有化监控与自动化告警体系  
**适用环境**：金融、政企等高安全合规要求场景  

---

### 1. 组件定位与设计目标

Azure Action Group（AG）是 Azure Monitor 告警体系中的**响应执行与编排中枢**，其核心职责不是“产生告警”，而是对已触发的告警进行**统一调度、分发与自动化处理**。

在企业级安全监控架构中，Action Group 承担以下关键角色：

- 解耦告警检测逻辑与响应执行逻辑  
- 作为多通知渠道与自动化能力的统一入口  
- 为后续告警增强、分流、自愈提供标准化触发点  

通过 Action Group 的引入，告警规则本身可以保持简洁稳定，而响应策略可独立演进。

---

### 2. 架构设计原则

Action Group 的设计遵循以下核心原则：

- **解耦原则**  
  告警规则仅负责“是否异常”，Action Group 负责“如何响应”。

- **标准化原则**  
  所有告警统一输出 Common Alert Schema，避免下游解析逻辑分裂。

- **最小暴露原则**  
  Action Group 仅作为触发器存在，不承载业务逻辑，不直接访问敏感系统。

- **可扩展原则**  
  支持多种通知与自动化成员并行扩展，而无需修改告警规则。

---

### 3. Action Group 组成与能力模型

一个 Action Group 由以下三类能力组成：

#### 3.1 通知型成员（Notify）

用于向人员或外部系统传递告警信息：

- Microsoft Teams（Webhook / App）
- Slack（Incoming Webhook）
- Email（角色或用户）
- SMS / Voice（高优先级场景）

#### 3.2 自动化型成员（Act）

用于触发自动化处理逻辑：

- Logic App（告警解析、增强、分流）
- Azure Function（自愈、内网中转）
- Automation Runbook（基础设施级操作）

#### 3.3 编排特性

- 并行触发多个成员  
- 支持告警级别与资源维度复用  
- 支持跨告警规则复用同一 Action Group  

---

### 4. Common Alert Schema 统一规范

#### 4.1 设计动因

在企业环境中，Action Group 的下游接收方通常包括多个系统（Logic App、Function、第三方 IM）。  
若告警数据结构不统一，将导致：

- 解析代码重复
- 分支逻辑膨胀
- 维护成本随告警类型线性增长

#### 4.2 规范要求

**所有 Action Group 成员必须启用 Common Alert Schema（V2）**。

该 Schema 提供：

- `essentials`：告警规则、严重级别、资源信息  
- `alertContext`：具体触发条件与上下文  

这是后续告警增强与分流逻辑的唯一稳定输入。

---

### 5. Action Group 在整体架构中的数据流角色

1. 告警规则（Metric / Log / Smart Detection）触发  
2. 告警状态进入 `Fired`  
3. Action Group 被激活  
4. 告警 Payload（Common Alert Schema）并行发送至各成员  
5. 下游系统基于 Schema 进行解析、增强与执行  

Action Group 本身不参与业务判断，仅负责**可靠触发与分发**。

---

### 6. 企业内网与 Private Link 场景下的特殊设计

#### 6.1 出站网络可达性

Action Group 的通知与自动化触发属于 **Azure 平台出站行为**，其 IP 地址不固定。

**强制要求**：

- 防火墙（Azure Firewall / NVA）必须放行 Service Tag：  
  `ActionGroup`

否则会导致：

- Webhook 调用失败  
- Logic App / Function 无法被触发  
- 告警“已触发但无响应”的隐蔽故障

---

#### 6.2 安全与身份校验

禁止以下做法：

- 在 Webhook URL 中硬编码 Token  
- 通过 QueryString 传递敏感凭据  

推荐方案：

- 在 Logic App 前置 API Management（APIM）  
- 通过 Header 特征、签名或请求频率进行校验  
- 将 Action Group 视为“半可信触发源”，而非完全可信客户端  

---

### 7. Action Group 与告警分级响应的关系

Action Group 本身不理解“P0 / P1 / P2”，但可作为分级响应的统一入口。

典型模式为：

- 告警规则中定义严重级别（Severity）  
- Logic App 根据 Severity 进行分流  

示例策略：

- **Sev0（Critical）**  
  - 电话 / 语音通知  
  - 自动化自愈（Function / Runbook）

- **Sev1（Error）**  
  - Teams / Slack 实时通知  
  - 自动创建 Jira 工单

- **Sev2（Warning）**  
  - 异步通知或汇总邮件  

---

### 8. 运维与治理要求

#### 8.1 基础设施即代码（IaC）

所有 Action Group 必须通过 Terraform 或 Bicep 创建与维护。

禁止行为：

- 直接在 Azure Portal 手工修改成员  
- 在不同环境中复制粘贴配置  

目的在于防止：

- 环境漂移  
- 响应策略不一致  
- 审计不可追溯  

---

#### 8.2 变更与审计

Action Group 的任何变更都应被视为 **生产级变更**：

- 成员新增 / 删除  
- 通知渠道变更  
- 自动化触发逻辑调整  

建议纳入：

- 变更评审流程  
- 代码审计与版本控制  

---

### 9. 架构级最佳实践总结

- Action Group 是“响应中枢”，不是逻辑引擎  
- 所有复杂逻辑必须下沉至 Logic App / Function  
- 始终启用 Common Alert Schema  
- 私有化监控不等于私有化告警出口，必须明确安全边界  
- Action Group 的稳定性直接决定告警体系是否“可信”  

---
