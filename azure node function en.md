# Azure Node.js Function Architecture Design (ASE – Internal Deployment)

## 1. Overall Architecture

### 1.1 Architectural Objective  
The solution deploys Azure Functions (v4, Node.js 18/20) inside an App Service Environment v3 (ASE) configured in Internal Load Balancer (ILB) mode. The objective is to provide a fully private, enterprise-grade serverless compute platform with no public ingress exposure. The architecture ensures network isolation, identity-based access control, and operational traceability aligned with regulated enterprise standards.

### 1.2 Core Components  
The architecture consists of an ASE v3 deployed in a delegated subnet, an Isolated v2 App Service Plan bound to the ASE, and a Linux-based Node.js Function App. Supporting components include Azure Storage (for runtime state), optional messaging services, and centralized monitoring via Application Insights and Log Analytics.

---

## 2. Network Architecture

### 2.1 Ingress Model  
All inbound traffic originates from the corporate network through VPN, ExpressRoute, or private peering. Internal DNS resolves the application domain to the ASE ILB private virtual IP. No public endpoints are exposed, and publishing endpoints are also internalized to prevent external deployment access.

### 2.2 Egress Model  
Outbound traffic from the Function App traverses the VNet. Dependent services such as Storage, Key Vault, or messaging systems are accessed via Private Endpoints. Public Network Access is disabled wherever possible. If internet access is required, traffic must pass through enterprise-controlled egress infrastructure with logging and allowlist policies.

---

## 3. Identity and Security Design

### 3.1 Managed Identity and RBAC  
The Function App uses a System Assigned Managed Identity for authentication. Storage access is configured using `storage_uses_managed_identity = true`, eliminating the need for access keys. RBAC roles such as Storage Blob Data Contributor and Storage Queue Data Contributor are granted at the appropriate scope. This ensures least-privilege access and avoids credential leakage in configuration or infrastructure state.

### 3.2 Application and Access Security  
HTTP triggers should integrate with Microsoft Entra ID or an enterprise API gateway to enforce authentication and authorization. Network-level isolation combined with RBAC and centralized logging forms the security baseline. All role assignments and configuration changes must be auditable to meet compliance standards such as SoX.

---

## 4. Deployment and Operations

### 4.1 Deployment Model  
Since ASE publishing endpoints are internal-only, deployment must be performed from within the VNet using a self-hosted CI/CD agent. Recommended deployment approaches include Run-From-Package or container-based deployment using a private Azure Container Registry. Configuration changes and application code releases should be managed independently to reduce rollback complexity.

### 4.2 Observability and Monitoring  
Application Insights captures logs, traces, and dependency telemetry. Diagnostic settings forward logs to a centralized Log Analytics workspace. Operational monitoring focuses on request latency, execution errors, dependency health, queue backlogs, and resource utilization to ensure production stability.

---

## 5. Availability, Scalability, and Governance

### 5.1 Scalability and Performance  
The Isolated v2 App Service Plan provides predictable compute resources and supports horizontal scaling based on workload demand. Capacity planning must consider concurrency levels, dependency throughput, and message processing rates to prevent bottlenecks.

### 5.2 Governance and Compliance  
Governance controls include centralized logging, role-based access reviews, infrastructure-as-code enforcement, and deployment traceability. High availability is achieved through multiple instances within the ASE. Optional cross-region disaster recovery can be implemented using replicated infrastructure and DNS-based failover mechanisms. The resulting architecture balances isolation, security, operational resilience, and long-term maintainability.
## tf code
### get the existing resources
```
data "azurerm_resource_group" "rg" {
  name = "rg-ase-prod"
}

data "azurerm_service_plan" "plan" {
  name                = "asp-ase-isolatedv2"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_storage_account" "sa" {
  name                = "stasefuncprod01"
  resource_group_name = data.azurerm_resource_group.rg.name
}
```
### Create a Linux Node Function

```
resource "azurerm_linux_function_app" "node_func" {
  name                = "func-node-ase-prod"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  service_plan_id      = data.azurerm_service_plan.plan.id
  storage_account_name = data.azurerm_storage_account.sa.name

  # 👇 关键：使用 MI 访问 Storage
  storage_uses_managed_identity = true

  https_only = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      node_version = "20"
    }

    ftps_state = "Disabled"
  }

  app_settings = {
    "FUNCTIONS_EXTENSION_VERSION" = "~4"
    "FUNCTIONS_WORKER_RUNTIME"    = "node"
    "WEBSITE_RUN_FROM_PACKAGE"    = "1"
  }
}
```
### assign Storage permission to the Identity of the Function 
 
The Functions runtime requires at least: 
 
Storage Blob Data Contributor 
 
Storage Queue Data Contributor
```
resource "azurerm_role_assignment" "blob_role" {
  scope                = data.azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.node_func.identity[0].principal_id
}

resource "azurerm_role_assignment" "queue_role" {
  scope                = data.azurerm_storage_account.sa.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_linux_function_app.node_func.identity[0].principal_id
}
```