# Azure Action Group Technical Design Document

**Component Type**: Alert Response and Automation Orchestration Hub  
**Applicable Architecture**: Azure Enterprise Secure Monitoring and Automated Alerting  
**Applicable Environments**: Financial institutions, government, and other high-security and compliance-driven environments  

---

## 1. Component Positioning and Design Objectives

Azure Action Group (AG) is the **response execution and orchestration hub** within the Azure Monitor alerting system. Its primary responsibility is not to generate alerts, but to **dispatch, route, and automate responses** for alerts that have already been triggered.

In an enterprise-grade secure monitoring architecture, Action Group plays the following critical roles:

- Decoupling alert detection logic from response execution logic  
- Serving as a unified entry point for multi-channel notifications and automation  
- Providing a standardized trigger mechanism for alert enrichment, routing, and self-healing  

By introducing Action Groups, alert rules remain stable and minimal, while response strategies can evolve independently.

---

## 2. Architectural Design Principles

The design of Action Groups follows several core architectural principles:

- **Decoupling Principle**  
  Alert rules determine *whether* an anomaly exists; Action Groups determine *how* the system responds.

- **Standardization Principle**  
  All alerts are emitted using the Common Alert Schema to prevent downstream parsing fragmentation.

- **Least Exposure Principle**  
  Action Groups act solely as triggers and do not host business logic or directly access sensitive systems.

- **Extensibility Principle**  
  Multiple notification and automation members can be added in parallel without modifying alert rules.

---

## 3. Action Group Composition and Capability Model

An Action Group consists of three primary capability categories:

### 3.1 Notification Members

Used to deliver alert information to human operators or external systems:

- Microsoft Teams (Webhook / App)
- Slack (Incoming Webhook)
- Email (role-based or user-based)
- SMS / Voice (high-severity scenarios)

### 3.2 Automation Members

Used to trigger automated processing and remediation logic:

- Logic App (alert parsing, enrichment, routing)
- Azure Function (self-healing, internal relay)
- Automation Runbook (infrastructure-level operations)

### 3.3 Orchestration Characteristics

- Parallel triggering of multiple members  
- Reusable across alert rules and resource scopes  
- Independent evolution of notification and automation strategies  

---

## 4. Common Alert Schema Standardization

### 4.1 Design Motivation

In enterprise environments, Action Group downstream consumers often include multiple systems (Logic Apps, Functions, third-party IM platforms). Without a unified alert schema, this typically results in:

- Duplicated parsing logic  
- Rapid growth of conditional branches  
- Increased long-term maintenance cost  

### 4.2 Standard Requirements

**All Action Group members must enable Common Alert Schema (V2).**

This schema provides:

- `essentials`: alert rule name, severity, affected resources  
- `alertContext`: triggering conditions and contextual metadata  

It serves as the single stable input contract for alert enrichment and routing logic.

---

## 5. Action Group Role in the End-to-End Alert Flow

1. Alert rules (Metric / Log / Smart Detection) are evaluated  
2. Alert state transitions to `Fired`  
3. Action Group is activated  
4. Alert payload (Common Alert Schema) is dispatched to all configured members in parallel  
5. Downstream systems parse, enrich, and execute response logic  

Action Groups do not perform business decisions; they are responsible solely for **reliable triggering and distribution**.

---

## 6. Enterprise Network and Private Link Considerations

### 6.1 Outbound Network Reachability

Action Group notifications and automation triggers are **Azure platform-initiated outbound calls**, and their source IP addresses are not fixed.

**Mandatory Requirement**:

- Firewalls (Azure Firewall or third-party NVAs) must explicitly allow outbound traffic for the Service Tag:  
  `ActionGroup`

Failure to do so may result in silent alert delivery failures.

---

### 6.2 Identity and Security Validation

The following practices are strictly prohibited:

- Hard-coded tokens embedded in Webhook URLs  
- Passing credentials via query strings  

Recommended approaches:

- Place Azure API Management (APIM) in front of Logic App triggers  
- Validate requests using headers, signatures, or behavioral characteristics  
- Treat Action Group as a *semi-trusted trigger source*, not a fully trusted client  

---

## 7. Action Group and Tiered Alert Response

Action Groups themselves do not interpret severity levels such as P0, P1, or P2. Instead, they act as a unified trigger point for tiered response logic implemented downstream.

A typical pattern includes:

- Defining alert severity in alert rules  
- Using Logic Apps to route responses based on severity  

Example strategy:

- **Sev0 (Critical)**  
  - Voice or phone notification  
  - Automated self-healing (Function / Runbook)

- **Sev1 (Error)**  
  - Real-time Teams or Slack notification  
  - Automatic Jira ticket creation

- **Sev2 (Warning)**  
  - Asynchronous notification or scheduled digest

---

## 8. Operations and Governance Requirements

### 8.1 Infrastructure as Code (IaC)

All Action Groups must be created and managed using Terraform or Bicep.

The following actions are prohibited:

- Manual modification via the Azure Portal  
- Environment-specific copy-paste configurations  

These restrictions are necessary to prevent configuration drift, inconsistency, and audit gaps.

---

### 8.2 Change Management and Auditing

Any modification to an Action Group must be treated as a **production-grade change**, including:

- Adding or removing members  
- Modifying notification channels  
- Adjusting automation triggers  

Such changes should be governed by:

- Formal change review processes  
- Version control and audit trails  

---

## 9. Architectural Best Practices Summary

- Action Groups are **response orchestrators**, not logic engines  
- Complex decision logic must reside in Logic Apps or Azure Functions  
- Common Alert Schema should always be enabled  
- Private telemetry ingestion does not imply private alert egress; security boundaries must be explicit  
- The reliability of Action Groups directly determines the trustworthiness of the alerting system  

---
