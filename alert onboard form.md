# 📘 Monitoring Onboarding Form  
## Azure Monitor Log Alert 接入申请表

---

## 1️⃣ 基础信息

| 字段 | 必填 | 示例 | 说明 |
|------|------|------|------|
| Application Name | ✅ | credit-api | 应用统一名称 |
| Environment | ✅ | dev / sit / uat / prod | 告警分环境管理 |
| Subscription ID | ✅ | xxxxx | 所在订阅 |
| Resource Group | ✅ | rg-credit-prod | 应用所在 RG |
| Deployment Type | ✅ | App Service / Function / AKS | 部署形态 |
| cloud_RoleName | ✅ | credit-api | KQL 隔离关键字段 |
| Business Owner | ✅ | 张三 | 业务负责人 |
| Technical Owner | ✅ | 李四 | 技术负责人 |

---

## 2️⃣ 日志接入确认

| 项目 | 是否完成 | 备注 |
|------|----------|------|
| Application Insights 已启用 | ☐ 是 ☐ 否 | |
| Workspace-based 模式 | ☐ 是 ☐ 否 | |
| Diagnostic Settings 已配置 | ☐ 是 ☐ 否 | |
| 关键依赖日志已开启 | ☐ 是 ☐ 否 | |

---

## 3️⃣ 可用性告警（Availability）

### 3.1 5xx 错误率监控

| 项目 | 必填 | 示例 |
|------|------|------|
| 是否启用 | ☐ 是 ☐ 否 | |
| 监控方式 | ☐ 错误数量 ☐ 错误率 | 推荐错误率 |
| 错误率阈值 | ✅ | 5% |
| 时间窗口 | ✅ | 5 分钟 |
| 最小请求量门槛 | 推荐 | 200 |
| Severity | ✅ | Sev1 |

---

## 4️⃣ 性能告警（Performance）

### 4.1 Latency 监控

| 项目 | 必填 | 示例 |
|------|------|------|
| 是否启用 | ☐ 是 ☐ 否 | |
| 指标 | ☐ p95 ☐ p99 | 推荐 p95 |
| 阈值 | ✅ | > 2000ms |
| 时间窗口 | ✅ | 5 分钟 |
| Severity | ✅ | Sev2 |

---

## 5️⃣ 依赖监控（Dependencies）

| 项目 | 必填 | 示例 |
|------|------|------|
| 是否启用 | ☐ 是 ☐ 否 | |
| 依赖类型 | SQL / Redis / External API | |
| 失败率阈值 | | 3% |
| 时间窗口 | | 5 分钟 |
| Severity | | Sev2 |

---

## 6️⃣ 异常监控（Exceptions）

| 项目 | 必填 | 示例 |
|------|------|------|
| 是否启用 | ☐ 是 ☐ 否 | |
| 是否排除已知异常 | ☐ 是 ☐ 否 | |
| 阈值 | | 50 / 5 分钟 |
| Severity | | Sev2 |

---

## 7️⃣ 告警分级确认

| Severity | 说明 | 选择 |
|----------|------|------|
| Sev0 | 全站不可用 | ☐ |
| Sev1 | 核心功能异常 | ☐ |
| Sev2 | 单模块异常 | ☐ |
| Sev3 | 性能预警 | ☐ |
| Sev4 | 观测类 | ☐ |

---

## 8️⃣ 通知与响应策略

| 项目 | 必填 | 示例 |
|------|------|------|
| Primary Email | ✅ | team@company.com |
| Teams Channel | 推荐 | #credit-alerts |
| 是否接入 ITSM | ☐ 是 ☐ 否 | |
| ITSM Group | | Credit Support |
| 是否需要自动化修复 | ☐ 是 ☐ 否 | |

---

## 9️⃣ 网络与安全（如适用）

| 项目 | 是否 |
|------|------|
| Workspace 已配置 Private Endpoint | ☐ 是 ☐ 否 |
| 使用 AMPLS | ☐ 是 ☐ 否 |
| Webhook 为内网地址 | ☐ 是 ☐ 否 |

---

## 🔟 DevOps 内部填写（非 Pod Team）

| 项目 | 填写 |
|------|------|
| Terraform Module Version | |
| Alert Naming Convention | |
| 审批人 | |
| 创建时间 | |
| 生效时间 | |

---

# 📌 说明

- 所有生产告警必须提供明确阈值与 Severity。
- DevOps 不代替业务定义 SLA。
- 默认推荐：
  - evaluation_frequency = 5m
  - failing_periods = 3/2
  - 使用错误率而非错误数量
  - KQL 必须包含时间窗口与 cloud_RoleName 过滤

---

# 🏗 标准流程

1. Pod Team 填写表单  
2. DevOps Review 阈值合理性  
3. PR 创建 Terraform Alert  
4. Code Review 审批  
5. Apply 部署  
6. 验证告警触发  

# 📘 Monitoring Onboarding Form  
## Azure Monitor Log Alert Integration Request

---

## 1️⃣ Basic Information

| Field | Required | Example | Description |
|--------|----------|----------|-------------|
| Application Name | ✅ | credit-api | Official application name |
| Environment | ✅ | dev / sit / uat / prod | Alert rules are environment-specific |
| Subscription ID | ✅ | xxxxx | Azure subscription where app is deployed |
| Resource Group | ✅ | rg-credit-prod | Resource group of the application |
| Deployment Type | ✅ | App Service / Function / AKS | Hosting type |
| cloud_RoleName | ✅ | credit-api | Critical for KQL isolation |
| Business Owner | ✅ | John Smith | Business owner |
| Technical Owner | ✅ | Jane Doe | Technical owner |

---

## 2️⃣ Logging Configuration Confirmation

| Item | Completed | Notes |
|------|-----------|-------|
| Application Insights Enabled | ☐ Yes ☐ No | |
| Workspace-based Mode Enabled | ☐ Yes ☐ No | |
| Diagnostic Settings Configured | ☐ Yes ☐ No | |
| Critical Dependency Logs Enabled | ☐ Yes ☐ No | |

---

## 3️⃣ Availability Alerts

### 3.1 5xx Error Monitoring

| Item | Required | Example |
|------|----------|----------|
| Enable Monitoring | ☐ Yes ☐ No | |
| Monitoring Method | ☐ Error Count ☐ Error Rate | Error Rate recommended |
| Error Rate Threshold | ✅ | 5% |
| Time Window | ✅ | 5 minutes |
| Minimum Request Threshold | Recommended | 200 |
| Severity | ✅ | Sev1 |

---

## 4️⃣ Performance Alerts

### 4.1 Latency Monitoring

| Item | Required | Example |
|------|----------|----------|
| Enable Monitoring | ☐ Yes ☐ No | |
| Metric | ☐ p95 ☐ p99 | p95 recommended |
| Threshold | ✅ | > 2000 ms |
| Time Window | ✅ | 5 minutes |
| Severity | ✅ | Sev2 |

---

## 5️⃣ Dependency Monitoring

| Item | Required | Example |
|------|----------|----------|
| Enable Monitoring | ☐ Yes ☐ No | |
| Dependency Type | SQL / Redis / External API | |
| Failure Rate Threshold | | 3% |
| Time Window | | 5 minutes |
| Severity | | Sev2 |

---

## 6️⃣ Exception Monitoring

| Item | Required | Example |
|------|----------|----------|
| Enable Monitoring | ☐ Yes ☐ No | |
| Exclude Known Exceptions | ☐ Yes ☐ No | |
| Threshold | | 50 / 5 minutes |
| Severity | | Sev2 |

---

## 7️⃣ Severity Classification

| Severity | Description | Selection |
|----------|-------------|-----------|
| Sev0 | Full system outage | ☐ |
| Sev1 | Critical functionality failure | ☐ |
| Sev2 | Module-level issue | ☐ |
| Sev3 | Performance degradation | ☐ |
| Sev4 | Informational / Observability | ☐ |

---

## 8️⃣ Notification & Response Strategy

| Item | Required | Example |
|------|----------|----------|
| Primary Email | ✅ | team@company.com |
| Teams Channel | Recommended | #credit-alerts |
| ITSM Integration Required | ☐ Yes ☐ No | |
| ITSM Support Group | | Credit Support |
| Auto-remediation Required | ☐ Yes ☐ No | |

---

## 9️⃣ Network & Security (If Applicable)

| Item | Yes / No |
|------|----------|
| Workspace Configured with Private Endpoint | ☐ Yes ☐ No |
| Using Azure Monitor Private Link Scope (AMPLS) | ☐ Yes ☐ No |
| Webhook Endpoint is Internal (Private Network) | ☐ Yes ☐ No |

---

## 🔟 DevOps Internal Section (For Platform Team Only)

| Item | Value |
|------|-------|
| Terraform Module Version | |
| Alert Naming Convention | |
| Approved By | |
| Created Date | |
| Effective Date | |

---

# 📌 Notes

- All production alerts must define explicit thresholds and severity levels.
- DevOps does not define SLA or business tolerance — this must be provided by the Pod Team.
- Recommended defaults:
  - evaluation_frequency = 5 minutes
  - failing_periods = 3/2
  - Prefer error rate over error count
  - KQL must include time window and cloud_RoleName filter

---

# 🏗 Standard Onboarding Workflow

1. Pod Team submits completed form  
2. DevOps reviews threshold and configuration  
3. Terraform alert rule created via Pull Request  
4. Code review and approval  
5. Deployment (terraform apply)  
6. Alert validation and testing  