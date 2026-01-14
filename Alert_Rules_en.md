# Azure Alert Rules Technical Design Document

**Component Type**: Alert Detection and Evaluation Engine  
**Applicable Architecture**: Azure Enterprise Secure Monitoring and Automated Alerting  
**Applicable Environments**: Financial institutions, government, and other high-security and compliance-driven environments  

---

## 1. Component Positioning and Responsibilities

Azure Alert Rules (commonly referred to as *Azure Action Alerts*) constitute the **detection and decision layer** within the Azure Monitor ecosystem. Their primary responsibility is to continuously evaluate telemetry data and determine **whether system behavior deviates from defined or learned baselines**.

In the overall monitoring architecture:

- Alert Rules decide **when an alert should be raised**
- Action Groups decide **how the alert should be handled**

This strict separation ensures that detection logic remains stable and auditable, while response strategies evolve independently.

---

## 2. Design Objectives

Azure Alert Rules are designed to achieve the following objectives:

- **Timely anomaly detection** without excessive noise  
- **Deterministic and auditable evaluation logic**  
- **Clear severity classification** to support tiered responses  
- **Minimal coupling** with notification and automation mechanisms  

---

## 3. Alert Rule Types and Use Cases

Azure Alert Rules are categorized based on the telemetry source and evaluation model.

### 3.1 Metric Alerts

**Description**:  
Metric Alerts evaluate numeric time-series data emitted by Azure resources.

**Typical Use Cases**:
- CPU, memory, and disk utilization thresholds  
- Network throughput and connection counts  
- Platform service health indicators  

**Key Characteristics**:
- Evaluation frequency: seconds to minutes  
- Low latency and predictable execution cost  
- Best suited for infrastructure and platform-level signals  

---

### 3.2 Log Search Alerts

**Description**:  
Log Search Alerts evaluate query results returned by Kusto Query Language (KQL) against Log Analytics data.

**Typical Use Cases**:
- Exception rate analysis  
- Business transaction failure detection  
- Cross-log correlation and pattern recognition  

**Key Characteristics**:
- Supports complex logic, joins, and aggregations  
- Enables business-context-aware alerting  
- Higher computational cost than metric alerts  

---

### 3.3 Smart Detection Alerts

**Description**:  
Smart Detection leverages Azure-built machine learning models to automatically identify anomalous patterns based on historical baselines.

**Typical Use Cases**:
- Sudden increase in failed requests  
- Latency degradation trends  
- Unknown or previously unmodeled anomalies  

**Key Characteristics**:
- Minimal manual configuration  
- Adaptive to workload behavior  
- Best used as a complement, not a replacement, for deterministic alerts  

---

## 4. Alert Evaluation Model

### 4.1 Evaluation Lifecycle

1. Telemetry data is ingested via private data paths  
2. Alert Rules execute evaluations at defined intervals  
3. Conditions are compared against thresholds or baselines  
4. Alert state transitions occur (`Activated`, `Fired`, `Resolved`)  
5. Action Group is invoked upon state change  

Alert Rules themselves do not send notifications; they only emit state changes.

---

### 4.2 Evaluation Frequency and Trade-offs

Alert evaluation frequency must balance **timeliness** and **cost efficiency**:

- High-frequency evaluations improve responsiveness but increase compute cost  
- Low-frequency evaluations reduce cost but may delay detection  

Typical enterprise practice is to configure:

- **Metric Alerts**: 1–5 minutes  
- **Log Search Alerts**: 5 minutes or longer, depending on query complexity  

---

## 5. Severity Classification Strategy

Alert Rules must explicitly assign severity levels to support downstream routing and response.

### Recommended Severity Mapping

- **Sev0 (Critical)**  
  Immediate service impact or data loss risk

- **Sev1 (Error)**  
  Functional degradation requiring prompt attention

- **Sev2 (Warning)**  
  Early indicators or non-blocking anomalies

Severity classification is treated as **part of detection logic**, not response logic.

---

## 6. Noise Reduction and Alert Quality Control

To maintain alert credibility and prevent fatigue, Alert Rules must be carefully tuned.

### Recommended Practices

- Use **aggregation windows** to avoid transient spikes  
- Apply **minimum occurrence thresholds**  
- Implement **deduplication logic** through alert state transitions  
- Avoid overlapping alert rules for the same symptom  

High-quality alerts are preferred over high-volume alerts.

---

## 7. Security and Compliance Considerations

### 7.1 Private Data Evaluation

All alert evaluations must operate exclusively on telemetry ingested through private endpoints and Private Link scopes. Public ingestion paths are not permitted in regulated environments.

---

### 7.2 Data Minimization

Alert rules should query and evaluate **only the fields necessary** for decision-making.

In Log Search Alerts, KQL queries must explicitly remove sensitive fields using `project-away` to prevent sensitive data from entering downstream alert payloads.

---

## 8. Integration with Action Groups

Alert Rules are tightly integrated with Action Groups but remain functionally independent.

### Integration Characteristics

- Each Alert Rule can reference one or more Action Groups  
- Action Groups are triggered only on state changes  
- Alert payloads are emitted using Common Alert Schema (V2)  

This design ensures consistency across notification and automation workflows.

---

## 9. Infrastructure as Code and Governance

### 9.1 IaC Requirements

All Alert Rules must be defined and managed via Terraform or Bicep.

Manual creation or modification via the Azure Portal is prohibited to ensure:

- Configuration consistency across environments  
- Full version traceability  
- Audit readiness  

---

### 9.2 Change Management

Any change to Alert Rules must be treated as a production-level change, including:

- Threshold adjustments  
- Query logic modifications  
- Severity reclassification  

Such changes should undergo review, testing, and controlled rollout.

---

## 10. Architectural Best Practices Summary

- Alert Rules define **when** an issue exists, not **how** it is resolved  
- Deterministic rules form the backbone of reliable alerting  
- Smart Detection complements but does not replace explicit rules  
- Severity classification is a detection responsibility  
- Well-designed alerts are scarce, actionable, and trusted  

---
