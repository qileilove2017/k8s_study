# 📘 Power Platform Monitoring Onboarding Form (Minimal)
## Azure Monitor Log Alert (Power Apps / Power Platform Logs)

---

# 1️⃣ Monitoring Target (Required)

| Field | Required | Example | Notes |
|------|----------|---------|------|
| Target Type | ✅ | Power Apps / Power Automate / Dataverse | What you want to monitor |
| Alert Purpose | ✅ | High failure count when opening app / Flow run failures | One sentence objective |
| Environment Name | ✅ | PROD-PP-ENV | Used for scoping |
| Environment ID (if available) | Recommended | 00000000-0000-0000-0000-000000000000 | More stable identifier |

---

# 2️⃣ Log Analytics Workspace (Required)

| Field | Required | Example |
|------|----------|---------|
| Workspace Name | ✅ | law-pp-prod |
| Workspace Resource ID | ✅ | /subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/... |

> Alert Engine queries data only from the Workspace via KQL.

---

# 3️⃣ Log Table & Fields (Required)

> Power Platform logs typically do NOT contain `cloud_RoleName`. You must confirm table name and usable fields.

| Field | Required | Example | Notes |
|------|----------|---------|------|
| Log Table Name | ✅ | AzureDiagnostics / PowerPlatformLogs | The actual table in your workspace |
| Key Filter Fields | ✅ | AppName / AppId / FlowName / FlowId / EnvironmentName / ResourceId | Used to scope to a specific app/flow/env |
| Success/Failure Field | ✅ | ResultType / Status / IsSuccess / httpStatusCode | Defines what “failure” means |
| Time Field | ✅ | TimeGenerated | Must be used for time window |

---

# 4️⃣ Alert Definition (Core Required: Workspace + KQL)

| Field | Required | Example |
|------|----------|---------|
| KQL Query | ✅ | (Provide full KQL) |
| Metric Column Name | ✅ | failCount / errorRate | Must match `summarize` output column |
| Operator | ✅ | GreaterThan / GreaterThanOrEqual | |
| Threshold | ✅ | 10 / 0.05 | Count or rate |
| Evaluation Frequency | Recommended | PT5M | Default 5 minutes |
| Window Duration | Recommended | PT5M | Default 5 minutes |
| Failing Periods (N/M) | Recommended | 3/2 | Debounce to reduce noise |
| Severity | ✅ | Sev1 / Sev2 / Sev3 | Must be defined |

---

# 5️⃣ Notification (Action Group Info)

| Field | Required | Example |
|------|----------|---------|
| Primary Email | ✅ | pp-pod-oncall@company.com |
| Teams Channel (if any) | Optional | #pp-alerts |
| ITSM Required | ☐ Yes ☐ No | |
| Webhook Required | ☐ Yes ☐ No | If internal, specify details |

---

# 6️⃣ KQL Quality Checklist (Before Submission)

- ☐ Must include time window (e.g., `TimeGenerated >= ago(5m)`)
- ☐ Must include `summarize` producing a numeric metric column
- ☐ Must filter by environment/app/flow fields (avoid querying entire workspace)
- ☐ Metric column name exactly matches Terraform `metric_measure_column`
- ☐ Threshold and severity confirmed by Pod Team

---

# 📌 Notes

- This onboarding form targets Power Platform logs (not Application Insights SDK telemetry).
- Alert Engine requires only: **Workspace + KQL**.
- DevOps owns Terraform implementation; Pod Team owns KQL correctness, scoping fields, and thresholds.

---

# 🏗 Workflow

1. Pod Team submits the form with KQL  
2. DevOps reviews (fields/time window/metric column/threshold)  
3. Terraform PR created/updated  
4. Code review & approval  
5. Deploy  
6. Validate alert firing/resolving and notification routing

# 📘 Power Platform 监控接入申请表（极简版）
## Azure Monitor Log Alert（Power Apps / Power Platform 日志）

---

# 1️⃣ 接入目标（必填）

| 字段 | 是否必填 | 示例 | 说明 |
|------|----------|------|------|
| 监控对象类型 | ✅ | Power Apps / Power Automate / Dataverse | 选择你要监控哪类日志 |
| 告警目的 | ✅ | App 打开失败次数过高 / Flow 运行失败 | 用一句话说明要监控什么 |
| 环境名称（Environment） | ✅ | PROD-PP-ENV | 用于过滤与归属 |
| Environment ID（如有） | 推荐 | 00000000-0000-0000-0000-000000000000 | 更稳定的定位字段 |

---

# 2️⃣ Log Analytics Workspace（必填）

| 字段 | 是否必填 | 示例 |
|------|----------|------|
| Workspace Name | ✅ | law-pp-prod |
| Workspace Resource ID | ✅ | /subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/... |

> Alert Engine 只从 Workspace 读取数据并执行 KQL。

---

# 3️⃣ 日志表与字段确认（必填）

> Power Platform 日志不会有 cloud_RoleName。必须明确“表名 + 可用字段”。

| 字段 | 是否必填 | 示例 | 说明 |
|------|----------|------|------|
| 日志表名 | ✅ | AzureDiagnostics / PowerPlatformLogs | 你 Workspace 里实际存在的表 |
| 关键过滤字段 | ✅ | AppName / AppId / FlowName / FlowId / EnvironmentName / ResourceId | 用于定位到具体应用/流程 |
| 成功/失败字段 | ✅ | ResultType / Status / IsSuccess / httpStatusCode | 用于定义失败判定 |
| 时间字段 | ✅ | TimeGenerated | KQL 时间窗口必须用它 |

---

# 4️⃣ 告警定义（核心必填：Workspace + KQL）

| 字段 | 是否必填 | 示例 |
|------|----------|------|
| KQL 查询语句 | ✅ | （提供完整 KQL） |
| 度量列名称（metric column） | ✅ | failCount / errorRate | KQL `summarize` 输出列名 |
| 比较符（operator） | ✅ | GreaterThan / GreaterThanOrEqual | |
| 阈值（threshold） | ✅ | 10 / 0.05 | 数量或比例 |
| 执行频率（evaluation_frequency） | 建议 | PT5M | 默认 5 分钟 |
| 时间窗口（window_duration） | 建议 | PT5M | 默认 5 分钟 |
| 抗抖动策略（N/M） | 建议 | 3/2 | 近 3 次至少 2 次超阈值 |
| 严重级别（Severity） | ✅ | Sev1 / Sev2 / Sev3 | 必须明确 |

---

# 5️⃣ 通知配置（Action Group 信息）

| 字段 | 是否必填 | 示例 |
|------|----------|------|
| 主要通知邮箱 | ✅ | pp-pod-oncall@company.com |
| Teams 通道（如有） | 可选 | #pp-alerts |
| 是否接入 ITSM | ☐ 是 ☐ 否 | |
| 是否需要 Webhook | ☐ 是 ☐ 否 | 内网接口需说明 |

---

# 6️⃣ KQL 最低质量要求（提交前自检）

- ☐ 必须包含时间窗口（例如：`TimeGenerated >= ago(5m)`）
- ☐ 必须包含 `summarize` 输出一个数值列
- ☐ 必须用“环境/应用/流程”相关字段做过滤（避免统计整个 Workspace）
- ☐ 度量列名称与 Terraform `metric_measure_column` 完全一致
- ☐ 阈值与 Severity 已由业务/Pod Team 确认

---

# 📌 重要说明

- 本体系不依赖 Application Insights SDK 字段（如 cloud_RoleName）。
- Alert Engine 运行只依赖：**Workspace + KQL**。
- DevOps 负责 Terraform 创建规则；Pod Team 负责提供正确的 KQL、过滤字段和阈值口径。

---

# 🏗 接入流程

1. Pod Team 填写表单并提供 KQL  
2. DevOps Review（字段/时间窗/度量列/阈值）  
3. Terraform PR 创建/更新 Alert Rule  
4. Code Review 审批  
5. 部署生效  
6. 触发验证（确认 Fired/Resolved 与通知链路）