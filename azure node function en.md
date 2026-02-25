# Azure Node.js Function (ASE Internal) – Simple Architecture Overview

## 1. Purpose

This architecture deploys a **Node.js Azure Function** inside an **App Service Environment v3 (ASE, ILB mode)** to achieve:

- No public internet exposure  
- Internal-only access via corporate network  
- Managed Identity authentication (no access keys)  
- Basic monitoring and logging  

This is suitable for enterprise internal systems requiring network isolation and compliance.

---

## 2. Architecture Overview

### Ingress (Internal Only)

Internal User / Internal Service  
→ Corporate Network (VPN / ExpressRoute)  
→ VNet  
→ ASE ILB (Private IP)  
→ Node.js Function App  

The Function is **not publicly accessible**.

---

## 3. Core Components

### App Service Environment (ASE v3)
- Deployed in a dedicated subnet  
- Internal Load Balancer mode  
- Provides private ingress endpoint  

### App Service Plan (Isolated v2)
- Runs inside ASE  
- Required for Function Apps in ASE  

### Azure Function (Linux + Node.js)
- Runtime: Functions v4  
- Node.js 18 or 20  
- Deployed into the existing ASE Plan  

### Storage Account
- Required by Azure Functions runtime  
- Access via Managed Identity (no storage key)

---

## 4. Security Design

### Identity
- System Assigned Managed Identity enabled  
- RBAC used for Storage access  
- No `primary_access_key` usage  

### Network
- ASE in ILB mode (internal only)  
- Optional: Storage with Private Endpoint  

### Access Control
- Internal DNS mapping to ASE private IP  
- Optional: Entra ID authentication for HTTP endpoints  

---

## 5. Storage Access (Recommended Configuration)

Use Managed Identity instead of access keys:

```hcl
storage_uses_managed_identity = true
Assign roles:

Storage Blob Data Contributor

Storage Queue Data Contributor

This prevents credentials from being stored in code or Terraform state.

6. Deployment Model

Because ASE Publishing is internal:

Deployment must occur from inside the VNet

Use self-hosted CI/CD agent

Recommended: Run-From-Package deployment

7. Monitoring

Minimum monitoring setup:

Application Insights enabled

Logs and metrics sent to Log Analytics

Monitor:

Request latency

Error rate

Function execution failures

Storage connectivity
9. Key Design Principles

Internal-only network exposure

No long-lived credentials

Role-based access control

Centralized logging

Simple and maintainable setup

10. Summary

This solution provides a secure and clean architecture for running Node.js Azure Functions inside ASE with:

Internal-only access

Managed Identity authentication

Enterprise-ready security posture

Basic observability

It is suitable for regulated enterprise environments requiring private workloads.