# Production Environment – IT Information Confirmation Document  
## Azure Private Log Export & Event Processing Architecture

**Document Purpose**  
This document is used to collect and confirm all mandatory IT and infrastructure information required to provision and operate the **Production (PROD)** environment for the Azure private log export and event-driven processing architecture.

The confirmed information will be used as direct input for Terraform (IaC) implementation and production deployment.

---

## 1. Subscription Information (Production)

**Decision Required:**  
☐ Use existing subscription  
☐ Create / assign new subscription  

### If using an existing subscription, please provide:
- **Subscription Name**:
- **Subscription ID**:
- **Tenant ID**:
- **Subscription Owner / Platform Team Contact**:
- **Compliance Boundary** (e.g. PROD-only / Shared / Regulated):

---

## 2. Resource Group Strategy (Production)

**Decision Required:**  
☐ Use existing Resource Group  
☐ Create new Resource Group via Terraform  

### If using an existing Resource Group:
- **Resource Group Name**:
- **Region**:
- **Subscription ID**:
- **Naming Convention Compliance** (Yes / No):

### If creating a new Resource Group via Terraform, please confirm:
- **Target Region**:
- **Resource Group Naming Pattern**:
- **Required Tags** (CostCenter / Environment / Owner / DataClassification):

---

## 3. App Service Plan (Azure Function Hosting)

**Decision Required:**  
☐ Use existing App Service Plan  
☐ Create new App Service Plan via Terraform  

### If using an existing App Service Plan:
- **Plan Name**:
- **Resource Group**:
- **Region**:
- **Plan Type** (Premium / Dedicated):
- **SKU** (e.g. EP1 / EP2 / P1v2):
- **Zone Redundancy Enabled** (Yes / No):
- **Available Capacity for New Function Apps** (Yes / No):

### If creating a new App Service Plan via Terraform, please confirm:

**Recommended for PROD**
- **Plan Type**: Premium (EP1–EP3)
- **Minimum Instances**: 2–4
- **Zone Redundancy**: Enabled
- **Max Burst Instances**: 20–50 (based on traffic)

**Terraform input required:**
- Plan Name
- SKU (EP1 / EP2 / EP3)
- Region
- Zone Redundancy (true / false)
- Minimum Instance Count
- Maximum Elastic Worker Count

---

## 4. Log Analytics Workspace (Production)

**Decision Required:**  
☐ Use existing Log Analytics Workspace  
☐ Create new Workspace via Terraform  

### If using an existing Log Analytics Workspace:
- **Workspace Name**:
- **Workspace ID**:
- **Resource Group**:
- **Region**:
- **Retention Period (days)**:
- **Linked Application Insights** (Yes / No):

### If creating a new Workspace via Terraform, please confirm:
- Workspace Name
- Region
- Retention Period (recommended: 30–90 days)
- Daily Ingestion Cap (if any)
- Required Tags

---

## 5. Log Analytics Data Export (PROD)

**Decision Required:**  
☐ Already created manually by POD team  
☐ To be created via Terraform  

### If already created manually:
- **Workspace Name**:
- **Export Rule Name**:
- **Destination Event Hub Namespace ID**:
- **Exported Tables** (e.g. AppRequests, AppExceptions):
- **Export Status** (Enabled / Disabled):

### If to be created via Terraform, please provide:

**Terraform input required:**
- Log Analytics Workspace Name or ID
- Data Export Rule Name
- Destination Event Hub Namespace ID
- Table Names to Export (list)
- Export Enabled (true / false)

---

## 6. Event Hub Namespace & Event Hub (Production)

**Decision Required:**  
☐ Use existing Event Hub Namespace / Hub  
☐ Create via Terraform  

### If using existing resources:
- **Namespace Name**:
- **Event Hub Name**:
- **Resource Group**:
- **Region**:
- **SKU** (Standard / Premium):
- **Throughput Units / Processing Units**:
- **Partition Count**:
- **Message Retention (days)**:
- **Private Endpoint Enabled** (Yes / No):

### If creating via Terraform, please confirm (based on recommended configuration):

**Namespace**
- SKU: Premium
- Availability Zones: Enabled
- Private Endpoint: Enabled
- Disaster Recovery: Enabled (if required)

**Event Hub**
- Partition Count: 8–32
- Message Retention: 7 days
- Capture Feature: Enabled (if audit required)
- Consumer Groups: `$Default` + custom (if required)

---

## 7. Azure Function App (Production)

**Decision Required:**  
☐ Use existing Function App  
☐ Create new Function App via Terraform  

### If using an existing Function App:
- **Function App Name**:
- **Resource Group**:
- **Region**:
- **Hosting Plan Name**:
- **Runtime Stack** (Python / .NET):
- **Runtime Version**:
- **VNet Integration Enabled** (Yes / No):

### If creating via Terraform, please confirm:

**Required Configuration**
- Function App Name
- Hosting Plan ID
- Runtime: Python
- Runtime Version: ~4 (LTS)
- Python Version: 3.11 or 3.12
- Managed Identity: System-assigned
- VNet Integration Subnet ID

**Key App Settings (PROD)**
- Event Hub Connection via Managed Identity
- Checkpoint Storage Account Name
- Consumer Group Name
- Batch Size
- Retry Policy
- Dead Letter Queue Name

---

## 8. Storage Account (Production)

**Decision Required:**  
☐ Use existing Storage Account  
☐ Create new Storage Account via Terraform  

### If using an existing Storage Account:
- **Storage Account Name**:
- **Resource Group**:
- **Region**:
- **Redundancy** (ZRS / GZRS):
- **Public Network Access** (Disabled / Enabled):
- **Private Endpoint Enabled** (Yes / No):

### If creating via Terraform, recommended PROD configuration:
- Account Kind: StorageV2
- Performance Tier: Standard
- Redundancy: ZRS or GZRS
- Access Tier: Hot
- Versioning: Enabled
- Soft Delete: Enabled (30 days)
- Public Access: Disabled
- Private Endpoints: Blob / Queue / Table

---

## 9. Storage Container / Queue / Table

**Decision Required:**  
☐ Use existing containers / queues / tables  
☐ Create via Terraform  

### If using existing resources:
- **Storage Account Name**:
- **Container Names**:
- **Queue Names**:
- **Table Names**:

### If creating via Terraform, please confirm:
- Container Names (list)
- Queue Names (list)
- Table Names (list)
- Access Level (private)

---

## 10. IAM & Ownership Confirmation

- **Deployment Identity (Terraform / Pipeline)**:
  - Confirmed RBAC assigned (Contributor / Storage Account Contributor / Network Contributor)

- **Runtime Identity (Azure Function Managed Identity)**:
  - Confirmed Data Plane roles only (Event Hub Data Receiver, Storage Data Contributors)

---

## Final Confirmation

☐ All required information provided  
☐ Approved for Terraform implementation  
☐ Approved for PROD deployment  

**Approver Name / Team**:  
**Date**:

---
