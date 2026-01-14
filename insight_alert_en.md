# Azure Enterprise Secure Monitoring and Automated Alerting  
## Technical Architecture Design Document

**Document Status**: Final  
**Architect**: Gemini (Enterprise Architect)  
**Applicable Scenarios**: Financial institutions, government, and other environments with strict security and compliance requirements  

---

## 1. Business Background and Architectural Objectives

In the process of enterprise digital transformation, core business systems are typically deployed in strictly controlled private or internal network environments. When implemented in such contexts, traditional cloud monitoring solutions often face a structural conflict between **security isolation** and **real-time observability**. On the one hand, enterprises seek to leverage cloud-native monitoring and intelligent analytics capabilities; on the other hand, telemetry data must not traverse public networks in order to prevent potential data leakage and compliance risks.

This architecture aims to establish a **zero public exposure** enterprise-grade secure monitoring and automated alerting system. By fully leveraging Azure native monitoring and automation capabilities, the solution delivers end-to-end observability and closed-loop response while meeting stringent security and regulatory requirements.

### Core Objectives

- **End-to-End Private Data Ingestion**  
  All telemetry data is transmitted exclusively through private network paths, eliminating any form of public internet exposure.

- **Compliance and Audit Readiness**  
  Monitoring data is sanitized and reduced prior to alert triggering and external notification, ensuring compliance with data flow auditing requirements.

- **High Reliability and Automated Self-Healing**  
  Automated alerting and remediation mechanisms significantly reduce Mean Time to Recovery (MTTR) and improve overall system resilience.

---

## 2. Technical Architecture Overview

> This architecture adopts a classic **three-layer monitoring model**, decoupling data ingestion, intelligent detection, and response execution to ensure clear security boundaries, strong scalability, and centralized governance.

- **Data Plane**: Responsible for private telemetry ingestion and isolation  
- **Intelligence Layer**: Responsible for anomaly detection, rule evaluation, and intelligent analysis  
- **Action Layer**: Responsible for alert notification, automated remediation, and external system integration  

---

## 3. Core Components

### 3.1 Data Plane: Private Isolation

#### Azure Monitor Private Link Scope (AMPLS)

**Architectural Rationale**:  
AMPLS acts as a logical private access hub for monitoring resources, allowing Application Insights and Log Analytics to be consolidated under private endpoints. This prevents telemetry data from being routed to untrusted networks and forms the foundation of a zero-public-exposure monitoring architecture.

#### Private Endpoint (PE)

**Engineering Constraints and Design Considerations**:  
Due to the global endpoint model used by Azure Monitor, a single virtual network is generally recommended to associate with only one AMPLS to avoid DNS resolution conflicts and unpredictable routing behavior. In enterprise Hub-Spoke network architectures, AMPLS is therefore typically deployed in the central Hub VNet.

#### Private DNS Zones

**Key Configuration Requirements**:  
Private DNS zones such as `privatelink.monitor.azure.com` must be correctly configured and linked to ensure that monitoring SDKs and agents resolve monitoring endpoints through private DNS records.

---

### 3.2 Intelligence Layer: Smart Monitoring

#### Metric Alerts

- **Applicable Scenarios**: Infrastructure and platform-level metrics (CPU, memory, connection count, etc.)
- **Advantages**: Low latency (minute-level), simple rule definitions, and predictable resource consumption

#### Log Search Alerts

- **Technology Selection**: Based on Kusto Query Language (KQL)
- **Key Advantages**: Supports cross-table joins and complex logic, enabling correlation between request logs, exception logs, and custom business logs to detect advanced business-level anomalies.

#### Smart Detection

- **Capability Overview**: Azure-built AI models automatically learn historical baselines and identify anomalies that are difficult to define using static thresholds, such as sudden spikes in failure rates or response time drift.
- **Applicable Scenarios**: Unknown anomalies and abrupt behavioral changes.

---

### 3.3 Action Layer: Closed-Loop Response

#### Action Groups (AG)

**Architectural Role**:  
Action Groups serve as the centralized orchestration and decoupling mechanism for alert responses, enabling a clean separation between **alert generation** and **alert execution**.

**Supported Capabilities**:
- Multi-channel notifications (Teams, Slack, Email, etc.)
- Automated execution (Azure Function, Logic App, Runbook)
- Parallel and conditional triggering

---

## 4. Logical Architecture and Data Flow

| Stage | Description | Technical Implementation and Rationale |
|------|------------|------------------------------------------|
| Ingestion | SDK captures telemetry and sends it through private networking | Application Insights SDK uses asynchronous, non-blocking design to avoid impacting business workloads |
| Storage | Data is ingested into logically isolated workspaces | Log Analytics applies configurable retention and storage policies to balance compliance and cost |
| Evaluation | Alert engine periodically evaluates rules | Query execution runs every 1–5 minutes, balancing timeliness and compute cost |
| Triggering | Alert state transitions to *Fired* | Built-in deduplication prevents alert storms |
| Response | Action Group is activated | Notification and automation paths are triggered in parallel |

---

## 5. Alert Notification and Integration Architecture

Under a Private Link deployment, telemetry ingestion is fully private. However, alert notifications often need to reach external SaaS platforms, making a secure and controlled egress design essential.

### 5.1 Notification Channel Implementation Strategies

| Channel | Implementation | Architectural Recommendation |
|-------|----------------|-------------------------------|
| Microsoft Teams | Native Webhook / App | Preferred option; highest security and support for Adaptive Cards |
| Slack | Incoming Webhook | Standard JSON payload; firewall must allow Action Group Service Tag |
| Email | Azure role-based notification | Recommended only for low-priority P2/P3 summary alerts |
| Internal IM (Feishu / DingTalk) | Azure Function relay | Uses VNet Integration to access internal gateways with private IPs |

---

## 6.2 Advanced Design: Logic App Alert Enrichment and Routing

### Design Motivation

Raw Action Group Webhook payloads are highly technical and difficult for on-call engineers to quickly interpret. This reduces decision-making efficiency and increases response time.

### Implementation Logic

- **Parsing**  
  Extract key fields from the Common Alert Schema `essentials` section to quickly identify alert rules, severity, and affected resources.

- **Enrichment**  
  Query Log Analytics using alert identifiers or resource dimensions to retrieve exception stack traces and contextual logs.

- **Routing**  
  - **P0 (Critical)**: Voice call notification + automated self-healing  
  - **P1 (Error)**: Microsoft Teams rich adaptive card notification  
  - **P2 (Warning)**: Asynchronous notification or automated ticket creation  

---

## 7. Non-Functional Design Considerations in Enterprise Internal Networks

### Webhook Reachability

Action Group outbound IP addresses are not fixed. Firewalls (Azure Firewall or third-party NVAs) must explicitly allow outbound traffic for the `ActionGroup` Service Tag to ensure reliable notification delivery.

### Identity and Security Validation

Hard-coded tokens in Webhooks or downstream logic are strictly prohibited.  
It is recommended to place Azure API Management (APIM) in front of Logic App triggers, or to implement signature-based validation using request headers.

### Data Masking Strategy

KQL alert queries must use `project-away` to explicitly remove sensitive fields (such as `client_IP` and `user_ID`) to prevent sensitive data from being propagated to third-party platforms.

---

## 8. Architectural Best Practices (Architect’s Recommendations)

### Tiered Response Matrix

- **Sev0 (Critical)**: Automatic service or component restart + voice call notification  
- **Sev1 (Error)**: Real-time IM notification (Teams / Slack) + automatic Jira ticket creation  

### Idempotent Self-Healing Logic

All automated remediation scripts must be designed to be idempotent, ensuring that retries or duplicate triggers do not result in repeated restarts or inconsistent system states.

### Infrastructure as Code (IaC) Governance

All monitoring resources—including Alert Rules, Action Groups, and AMPLS—must be managed through Terraform or Bicep. Manual changes via the Azure Portal are strictly prohibited to prevent configuration drift.

### Cost Optimization Strategy

For non-critical anomalies, apply log sampling and conditional filtering to significantly reduce Log Analytics ingestion and storage costs without compromising observability.
