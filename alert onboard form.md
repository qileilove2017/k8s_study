# 📘 Monitoring Onboarding Form (Minimal Version)
## Azure Monitor Log Alert – Required Information

---

# 1️⃣ Application Identification

| Field | Required | Example | Description |
|--------|----------|----------|-------------|
| Application Name | ✅ | credit-api | Logical application name |
| Environment | ✅ | dev / sit / uat / prod | Alert environment |
| Subscription ID | ✅ | xxxxx | Azure subscription ID |
| Resource Group | ✅ | rg-credit-prod | Resource group |
| cloud_RoleName | ✅ | credit-api | Used for KQL filtering |

---

# 2️⃣ Log Analytics Workspace

| Field | Required | Example |
|--------|----------|----------|
| Workspace Name | ✅ | law-shared-prod |
| Workspace Resource ID | ✅ | /subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/... |

> Alert Engine requires Workspace as the data source.

---

# 3️⃣ Alert Definition (Core Requirement)

## 3.1 Alert Objective

| Field | Required | Example |
|--------|----------|----------|
| Alert Purpose | ✅ | 5xx Error Rate |
| KQL Query | ✅ | (Provide full KQL) |
| Metric Column Name | ✅ | errorRate |
| Operator | ✅ | GreaterThan |
| Threshold | ✅ | 0.05 |
| Evaluation Frequency | Recommended | PT5M |
| Window Duration | Recommended | PT5M |
| Failing Periods (N/M) | Recommended | 3/2 |
| Severity | ✅ | Sev1 |

> KQL must include time filter and summarize statement.

---

# 4️⃣ Action Group (Notification)

| Field | Required | Example |
|--------|----------|----------|
| Primary Email | ✅ | team@company.com |
| Teams Channel (if any) | Optional | #credit-alerts |
| ITSM Integration Required | ☐ Yes ☐ No |
| Webhook Required | ☐ Yes ☐ No |

---

# 5️⃣ Validation Checklist

Pod Team confirms:

- ☐ KQL has time window (e.g., ago(5m))
- ☐ KQL includes summarize statement
- ☐ cloud_RoleName filter applied
- ☐ Threshold reviewed and agreed
- ☐ Severity aligned with SLA

---

# 📌 Important Notes

- Alert Engine only requires: Workspace + KQL.
- Terraform will create the alert rule in Azure Monitor.
- DevOps does not define business thresholds.
- Production alerts must define severity explicitly.

---

# 🏗 Workflow

1. Pod Team submits this form
2. DevOps reviews KQL and threshold
3. Terraform alert rule created via PR
4. Code review & approval
5. Deployment
6. Alert validation

# 📘 监控接入申请表（极简版）
## Azure Monitor Log Alert 必需信息表

---

# 1️⃣ 应用标识信息

| 字段 | 是否必填 | 示例 | 说明 |
|------|----------|------|------|
| 应用名称 | ✅ | credit-api | 应用逻辑名称 |
| 环境 | ✅ | dev / sit / uat / prod | 告警所属环境 |
| 订阅 ID | ✅ | xxxxx | 应用所在订阅 |
| 资源组 | ✅ | rg-credit-prod | 应用所在资源组 |
| cloud_RoleName | ✅ | credit-api | KQL 查询隔离字段 |

---

# 2️⃣ Log Analytics Workspace 信息

| 字段 | 是否必填 | 示例 |
|------|----------|------|
| Workspace 名称 | ✅ | law-shared-prod |
| Workspace 资源 ID | ✅ | /subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/... |

> Alert Engine 通过 Workspace 执行 KQL 查询。

---

# 3️⃣ 告警定义（核心信息）

## 3.1 告警目标

| 字段 | 是否必填 | 示例 |
|------|----------|------|
| 告警目的 | ✅ | 5xx 错误率 |
| KQL 查询语句 | ✅ | （提供完整 KQL） |
| 度量列名称 | ✅ | errorRate |
| 比较符 | ✅ | GreaterThan |
| 阈值 | ✅ | 0.05 |
| 执行频率 | 建议 | PT5M |
| 时间窗口 | 建议 | PT5M |
| 抗抖动策略 (N/M) | 建议 | 3/2 |
| 严重级别 | ✅ | Sev1 |

> KQL 必须包含：
> - 时间过滤（例如 ago(5m)）
> - summarize 语句
> - cloud_RoleName 过滤

---

# 4️⃣ 通知配置（Action Group）

| 字段 | 是否必填 | 示例 |
|------|----------|------|
| 主要通知邮箱 | ✅ | team@company.com |
| Teams 通道（如有） | 可选 | #credit-alerts |
| 是否接入 ITSM | ☐ 是 ☐ 否 |
| 是否需要 Webhook | ☐ 是 ☐ 否 |

---

# 5️⃣ 校验清单

Pod Team 需确认：

- ☐ KQL 包含时间窗口
- ☐ KQL 包含 summarize
- ☐ 已添加 cloud_RoleName 过滤
- ☐ 阈值已确认合理
- ☐ 严重级别符合 SLA

---

# 📌 重要说明

- Alert Engine 运行仅依赖：Workspace + KQL。
- Terraform 负责在 Azure Monitor 中创建规则。
- DevOps 不负责定义业务阈值。
- 生产环境必须明确 Severity。

---

# 🏗 接入流程

1. Pod Team 填写表单  
2. DevOps 审核 KQL 与阈值  
3. 创建 Terraform PR  
4. 代码评审  
5. 部署生效  
6. 验证告警触发  