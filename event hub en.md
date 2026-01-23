# Azure Private Log Export and Event Processing Architecture Design Document

**Document Status**: Final  
**Intended Audience**: Architecture Review, Security & Compliance Review, Platform Engineering, Operations  
**Applicable Scenarios**: Financial services, government, and other highly regulated environments requiring zero public exposure  

---

## 1. Background and Design Objectives

In enterprise cloud platforms, operational logs and telemetry data often contain sensitive runtime information, exception details, and business context. From a security and compliance perspective, such data must be treated with the same protection level as core business data.

In regulated industries such as financial services and government sectors, traditional architectures based on **public ingestion and public processing paths** no longer meet internal control, audit, and data residency requirements.

This architecture aims to establish a:

- **Zero Public Exposure**
- **End-to-end private network–based**
- **Auditable, governable, and scalable**

Azure-native solution for **private log export and event-driven processing**.

---

## 2. High-Level Architecture Overview

The solution is built upon the following Azure-native capabilities:

- Azure Virtual Network (VNet)
- Private Endpoint and Private DNS Zones
- Log Analytics Data Export
- Azure Event Hubs for decoupled event ingestion
- Azure Functions for private event processing
- Azure Storage Account for secure persistence and state management

From log generation to export, processing, and storage, **all data flows remain within Azure private networking boundaries**, with no public internet exposure.

---

## 3. Virtual Network and Subnet Design

### 3.1 Virtual Network Parameters

| Item | Description |
|----|------------|
| VNet Type | Azure Virtual Network |
| Address Space | `10.x.x.0/16` (example) |
| Network Model | Hub-Spoke or isolated workload VNet |
| Public Access | Disabled (Private Endpoint only) |

The VNet serves as the **primary security and routing boundary** for all private communications and must be sized to support long-term growth.

---

### 3.2 Subnet Segmentation and Responsibilities

#### Subnet A: Outbound / Compute Subnet

| Item | Description |
|----|------------|
| Purpose | Azure Function outbound connectivity |
| Example CIDR | `10.x.1.0/24` |
| Delegation | `Microsoft.Web/serverFarms` |
| Private Endpoints Allowed | ❌ No |

This subnet is dedicated to **Azure Function VNet Integration (outbound)** and must not host Private Endpoints.

---

#### Subnet B: Inbound Private Endpoint Subnet

| Item | Description |
|----|------------|
| Purpose | Hosting all Private Endpoints |
| Example CIDR | `10.x.2.0/24` |
| Compute Resources | ❌ Not allowed |
| NSG Recommendation | Allow VNet-internal traffic only |

This subnet acts as a **centralized private ingress zone** for PaaS services such as Event Hubs and Storage Accounts.

---

## 4. DNS Architecture and Name Resolution (Critical Design)

In Private Endpoint–based architectures, DNS configuration is a critical dependency for system availability.

### 4.1 Required Private DNS Zones

| Service | Private DNS Zone |
|------|----------------|
| Azure Function | `privatelink.azurewebsites.net` |
| Event Hubs | `privatelink.servicebus.windows.net` |
| Storage Blob | `privatelink.blob.core.windows.net` |
| Storage Queue | `privatelink.queue.core.windows.net` |
| Storage Table | `privatelink.table.core.windows.net` |

---

### 4.2 DNS and VNet Relationship

- All Private DNS Zones must be **linked to the workload VNet**
- In Hub-Spoke models, zones are typically linked to the Hub VNet
- Private DNS Zones are associated with VNets, **not subnets**

---

## 5. End-to-End Data Flow Description

### Step 1: Log Analytics to Event Hub (Log Export)

- Log Analytics Workspace is configured with Data Export Rules
- Logs are continuously streamed to an Event Hub Namespace
- Event Hub exposes Private Endpoint only
- Name resolution resolves to private IPs via Service Bus Private Link

---

### Step 2: Event Hub to Azure Function (Event Processing)

- Azure Function uses **Event Hub Trigger**
- Dedicated Consumer Groups ensure consumption isolation
- Function accesses Event Hub via VNet Integration and Private Endpoint
- All traffic remains within the private network

---

### Step 3: Azure Function to Storage Account (Result Persistence)

- Azure Function uses Managed Identity for authentication
- Blob / Queue / Table services are accessed via Private Endpoints
- Storage public network access is disabled
- Authorization is enforced through RBAC

---

## 6. Azure Function Hosting and Runtime Selection

### 6.1 Hosting Plan Comparison

| Plan Type | Advantages | Limitations | Recommendation |
|--------|-----------|------------|---------------|
| Consumption Plan | Low cost, no capacity planning | Cold starts, unsuitable for continuous processing | ❌ Not recommended |
| **Premium Plan (Elastic Premium)** | VNet & PE support, pre-warmed instances, elastic scaling | Higher baseline cost | ✅ **Preferred** |
| Dedicated Plan | No cold start, predictable cost | Limited elasticity | ⚠️ Secondary option |
| Isolated Plan (ASE) | Maximum isolation | Very high cost and complexity | ❌ Use only if mandated |

**Conclusion**:  
For private, continuous, event-driven processing, **Elastic Premium Plan is the default recommended option**.

---

### 6.2 Azure Function Type and Trigger Model

| Aspect | Selection |
|----|---------|
| Function Type | Event-driven processing function |
| Trigger | **Event Hub Trigger** |
| Runtime | Python or .NET (team-dependent) |
| Idempotency | Mandatory |
| Network Access | VNet Integration (Outbound) |

---

## 7. Storage Account Type and Configuration

### 7.1 Storage Account Type Comparison

| Type | Description | Recommendation |
|----|------------|--------------|
| **StorageV2** | Full support for Blob / Queue / Table | ✅ |
| StorageV1 | Legacy | ❌ |
| Blob-only | Object storage only | ⚠️ Limited |
| Premium / File | Specialized workloads | ❌ |

---

### 7.2 Replication Strategy

| Replication | Usage Recommendation |
|-----------|---------------------|
| LRS | Non-critical / test |
| **ZRS** | ✅ Production default |
| GRS / GZRS | Audit, disaster recovery |

---

### 7.3 Security Configuration

- Public network access: Disabled  
- Access mode: Private Endpoint only  
- Authentication: Managed Identity + RBAC  
- Long-lived account keys: Prohibited  
- Lifecycle management: Enabled (Hot → Cool / Archive)

---

## 8. Security, Compliance, and Operations Considerations

### 8.1 Security and Compliance

- All communications use private IP addresses
- No public endpoints are exposed
- Network, identity, and access controls are fully auditable
- Architecture aligns with financial and government compliance standards

---

### 8.2 Common Engineering Risks

| Risk | Impact |
|----|-------|
| Missing or unlinked DNS zones | Service connectivity failures |
| Mixed subnet responsibilities | Security boundary violations |
| Incorrect Consumer Group usage | Data loss or duplicate processing |

---

## 9. Architecture Summary

This architecture establishes a robust and secure foundation by:

- Defining clear network boundaries using VNets
- Enforcing strict subnet responsibility separation
- Leveraging Private Endpoints and Private DNS for secure access
- Decoupling log ingestion via Event Hubs
- Processing events privately with Azure Functions
- Persisting results securely in Azure Storage

The design achieves a balanced combination of **security, stability, scalability, and auditability**, making it suitable as a standardized enterprise reference architecture for regulated environments.

---
