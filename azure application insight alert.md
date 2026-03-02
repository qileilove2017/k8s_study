# Azure Monitor Log Alert Architecture Design Specification

**Document Type:** Technical Architecture Design  
**Scope:** Enterprise Log-Based Alerting System  
**Target Environment:** Regulated / Private Network Deployments  

---

# 1. Architecture Objectives

This architecture establishes a log-based alerting framework that is:

- Infrastructure-as-Code driven (IaC)
- Audit-ready and compliant
- Horizontally scalable across services
- Decoupled between evaluation and notification
- Suitable for enterprise private network deployments

### Core Technology Stack

- Terraform  
- Azure Monitor  
- Log Analytics Workspace  
- Kusto Query Language (KQL)  
- Azure Monitor Action Groups  

---

# 2. Layered Architecture Model

The solution follows a three-layer design model:

| Layer | Component | Responsibility |
|-------|-----------|---------------|
| Control Plane | Azure Monitor API | Stores and manages alert definitions |
| Runtime Plane | Azure Alert Engine | Evaluates queries and determines state |
| Data Plane | Log Analytics Workspace | Stores logs and executes KQL queries |

This separation ensures scalability, clarity of responsibility, and operational isolation.

---

# 3. Component Design Details

---

## 3.1 Terraform (Infrastructure Declaration Layer)

Terraform is responsible for:

- Creating Log Analytics Workspaces  
- Defining Alert Rules  
- Creating Action Groups  
- Managing thresholds and KQL file references  

Terraform does **not**:

- Execute KQL queries  
- Perform runtime alert evaluation  
- Handle alert state transitions  

Terraform registers alert definitions with Azure Monitor.  
Execution is fully handled by Azure platform services.

---

## 3.2 Azure Monitor (Control Plane)

Azure Monitor Control Plane:

- Receives alert rule definitions  
- Stores and manages alert configurations  
- Handles enable/disable lifecycle  

### Characteristics

- Platform-managed service  
- Automatically available in all subscriptions  
- No explicit deployment required  

---

## 3.3 Alert Engine (Runtime Plane)

The Azure Alert Engine is the core execution component.

### Responsibilities

- Executes at configured `evaluation_frequency`
- Runs KQL queries against Log Analytics
- Evaluates `metric_measure_column`
- Applies `operator` and `threshold`
- Enforces `failing_periods` logic
- Manages alert state transitions (Fired / Resolved)

### Architectural Properties

- Runs inside Azure platform infrastructure  
- Does not consume customer compute resources  
- Does not reside inside customer VNet  
- Does not require Private Endpoint  

It communicates internally with Log Analytics via platform-managed secure channels.

---

## 3.4 Log Analytics Workspace (Data Plane)

The Workspace is responsible for:

- Storing Application Insights telemetry
- Executing KQL queries
- Serving query results to Alert Engine

### Common Tables

- `requests`
- `dependencies`
- `exceptions`
- `traces`

### Enterprise Design Recommendation

- Use a centralized or tiered workspace strategy
- Isolate services using `cloud_RoleName`
- Apply data retention and access governance policies

---

## 3.5 Action Group (Response Layer)

Action Groups are responsible for:

- Email notifications
- Microsoft Teams notifications
- Webhook calls
- ITSM ticket creation
- Azure Function automation triggers

### Key Architectural Principle

Alert Rules and Action Groups are fully decoupled.

- One Action Group can serve multiple Alert Rules
- Alert logic and notification logic evolve independently

---

# 4. Runtime Execution Flow

At each `evaluation_frequency` interval:

1. Alert Engine triggers execution
2. KQL query runs against Log Analytics
3. Result set is generated
4. `metric_measure_column` is extracted
5. Compared against `threshold`
6. `failing_periods` logic is evaluated
7. Alert transitions to **Fired** state if conditions persist
8. Associated Action Group is triggered

---

# 5. Network and Security Considerations

## 5.1 Private Endpoint Requirements

| Component | Private Endpoint Required |
|------------|--------------------------|
| Alert Engine | No |
| Azure Monitor Control Plane | No |
| Log Analytics Workspace | Recommended for enterprise private environments |
| Action Group Webhook | Required if target is internal API |

### Explanation

The Alert Engine operates inside Azure platform infrastructure and accesses Log Analytics through internal service channels.

Therefore:

- It does not require VNet presence
- It does not require Private Endpoint
- It does not expose public inbound paths

---

# 6. Architectural Advantages

---

## 6.1 Decoupled Evaluation and Notification

- Alert Rule evaluates conditions
- Action Group handles response

This reduces coupling and improves maintainability.

---

## 6.2 Infrastructure-as-Code Governance

- All alert definitions managed through Terraform
- Version-controlled configurations
- Supports audit requirements

---

## 6.3 Horizontal Scalability

- New services require only new KQL rules
- Existing Action Groups can be reused
- No architectural redesign required

---

## 6.4 Cost Control

- `evaluation_frequency` configurable
- Time window configurable
- Query scope controllable

This enables fine-grained cost optimization.

---

# 7. Best Practice Design Guidelines

---

## 7.1 Standardization Rules

All KQL rules must:

- Include explicit time window filters
- Include `cloud_RoleName` filtering
- Default to `failing_periods = 3 of 2` pattern (recommended)

---

## 7.2 Alert Severity Classification

| Severity | Usage |
|----------|-------|
| 0 | Full system outage |
| 1 | Critical API failure |
| 2 | Functional degradation |
| 3 | Performance degradation |
| 4 | Observability / Informational |

---

# 8. Architectural Summary

Core design philosophy:

- Terraform defines rules
- Azure Monitor stores rules
- Alert Engine evaluates rules
- Log Analytics provides data
- Action Group handles response

This architecture:

- Does not require provisioning Azure Monitor
- Does not require deploying Alert Engine
- Only requires defining alert rules and data sources

It provides:

- Enterprise-grade scalability
- Operational decoupling
- Compliance alignment
- Platform-managed reliability

# tf code demo
```
ai-log-alert-demo/
  main.tf
  variables.tf
  outputs.tf
  alerts/
    high_5xx.kql

```

```
let lookback = 5m;
requests
| where timestamp >= ago(lookback)
| where toint(resultCode) >= 500
| summarize errorCount = count()
```
variables.tf
```
variable "location" {
  type    = string
  default = "japaneast"
}

variable "resource_group_name" {
  type    = string
  default = "rg-ai-log-alert-demo"
}

variable "law_name" {
  type    = string
  default = "law-ai-log-alert-demo"
}

variable "app_insights_name" {
  type    = string
  default = "appi-ai-log-alert-demo"
}

variable "action_group_name" {
  type    = string
  default = "ag-ai-log-alert-demo"
}

variable "alert_rule_name" {
  type    = string
  default = "alert-high-5xx-demo"
}

variable "alert_email" {
  type        = string
  description = "Action Group email receiver"
  default     = "your_email@example.com"
}

variable "severity" {
  type    = number
  default = 1
}

variable "evaluation_frequency" {
  type    = string
  default = "PT5M"
}

variable "window_duration" {
  type    = string
  default = "PT5M"
}

variable "threshold" {
  type    = number
  default = 10
}

variable "tags" {
  type    = map(string)
  default = {
    managed_by = "terraform"
    purpose    = "demo"
  }
}
```
main.tf
```
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Log Analytics Workspace (Logs 存储与 KQL 查询范围)
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Application Insights (workspace-based)
resource "azurerm_application_insights" "ai" {
  name                = var.app_insights_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"

  workspace_id = azurerm_log_analytics_workspace.law.id
  tags         = var.tags
}

# Action Group（通知/自动化）
resource "azurerm_monitor_action_group" "ag" {
  name                = var.action_group_name
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "aialrt"
  tags                = var.tags

  email_receiver {
    name          = "oncall"
    email_address = var.alert_email
  }
}

# Scheduled Query Alert v2（KQL 告警规则）
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "alert_5xx" {
  name                = var.alert_rule_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  description          = "Fires when 5xx request count exceeds threshold in the window"
  enabled              = true
  severity             = var.severity
  evaluation_frequency = var.evaluation_frequency
  window_duration      = var.window_duration

  # 推荐 scope 指向 Log Analytics Workspace
  scopes = [azurerm_log_analytics_workspace.law.id]

  # 自动恢复告警（下一次评估不满足条件则 Resolved）
  auto_mitigation_enabled = true

  criteria {
    query                   = file("${path.module}/alerts/high_5xx.kql")
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = var.threshold

    # 必须与 KQL summarize 输出列名一致：errorCount
    metric_measure_column = "errorCount"

    # 抗抖动：最近 N 次里至少 M 次失败才触发
    failing_periods {
      number_of_evaluation_periods             = 1
      minimum_failing_periods_to_trigger_alert = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.ag.id]
  }

  tags = var.tags
}
```
outputs.tf
```
output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "application_insights_id" {
  value = azurerm_application_insights.ai.id
}

output "scheduled_query_alert_id" {
  value = azurerm_monitor_scheduled_query_rules_alert_v2.alert_5xx.id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.ag.id
}
```