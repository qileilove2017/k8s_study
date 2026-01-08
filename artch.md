
# Technical Specification: Azure Function (Linux Premium) Deployment Strategies

## 1. Executive Summary

This document outlines the deployment methodologies for Azure Functions (Python 3.11 / V4) on Linux Premium plans within a secured enterprise environment. The core requirement is to establish a **repeatable, auditable, and rollback-capable** workflow that operates entirely within a **Private Network (VNet/Private Endpoint)** and complies with the mandate to **disable SCM Basic Authentication**.

---

## 2. Global Pre-requisites: Python Packaging Standard

To ensure the Function runtime correctly identifies dependencies on Linux without manual `PYTHONPATH` manipulation, the following packaging standard is mandatory for all options:

* **Dependency Path**: `.python_packages/lib/site-packages`.
* **Build Requirement**: Pipelines must install requirements into this specific sub-folder during the build stage.
* **Structure Example**:
```text
/
├── host.json
├── requirements.txt
├── <FunctionName>/
│   ├── __init__.py
│   └── function.json
└── .python_packages/
    └── lib/
        └── site-packages/ ...

```



---

## 3. Option 1: ZipDeploy via Microsoft Entra (Bearer Token)

### 3.1 Overview

Utilizes an Azure CLI-generated **Microsoft Entra access token** to authenticate with the Kudu SCM `/api/zipdeploy` interface. This is the recommended default for environments where Basic Auth is blocked.

### 3.2 Workflow

1. **Auth**: Pipeline authenticates via Service Connection (Service Principal/Workload Identity).
2. **Token**: Retrieve token via `az account get-access-token`.
3. **Deploy**: HTTP POST the ZIP to `https://<app>.scm.azurewebsites.net/api/zipdeploy`.
4. **Monitor**: Poll `/api/deployments/latest` for real-time status and error logs.

---

## 4. Option 2: ZipDeploy via SCM Basic Auth (Legacy)

### 4.1 Overview

The traditional method using site-level deployment credentials (Publish Profile).

### 4.2 Status: ❌ PROHIBITED

* **Reason**: Directly conflicts with the enterprise security policy disabling Basic Auth.
* **Risks**: High credential management overhead and lack of RBAC integration.

---

## 5. Option 3: Run From Package (Blob SAS URL)

### 5.1 Overview

The Function App mounts its source code directly from a compressed ZIP file hosted on **Azure Storage** via the `WEBSITE_RUN_FROM_PACKAGE` setting.

### 5.2 Enterprise Private Network Configuration

To operate in a private environment, the following must be implemented:

* **Storage Account**: Private Endpoint (PE) enabled with a Private DNS Zone (`privatelink.blob.core.windows.net`).
* **Function App**: VNet Integration enabled to allow outbound access to the Storage PE.
* **App Setting**: Set `WEBSITE_VNET_ROUTE_ALL = 1` to ensure all traffic is routed through the VNet.

---

## 6. Comparison Matrix

| Dimension | Option 1: Bearer Token | Option 2: Basic Auth | Option 3: Run From Package |
| --- | --- | --- | --- |
| **Security Compliance** | ✅ High (Entra ID) | ❌ Non-compliant | ✅ High (SAS + PE) |
| **Rollback Speed** | Moderate (Redeploy) | Moderate | ✅ **Fast (Update URL)** |
| **Deployment Model** | Push-based | Push-based | **Artifact-based (Pull)** |
| **Network Constraint** | SCM Site Access | SCM Site Access | **Storage & VNet Access** |
| **Recommended Use** | Dev / Testing | **None** | **Production** |

---

## 7. Strategic Recommendations

### 7.1 Production Environment

* **Preferred Method**: **Option 3 (Run From Package)**.
* **Justification**: Supports "Immutable Artifacts" and provides the fastest recovery/rollback path by simply reverting the app setting.

### 7.2 Lower Environments (Dev/QA)

* **Preferred Method**: **Option 1 (Bearer Token)**.
* **Justification**: Simplifies the CI/CD pipeline by avoiding storage account management while remaining compliant with security policies.

---

## 8. Appendix: Recommended App Settings (Option 3)

| Setting | Value | Description |
| --- | --- | --- |
| `WEBSITE_RUN_FROM_PACKAGE` | `https://<sa>.blob.../<pkg>.zip?<sas>` | Directs runtime to the code package. |
| `SCM_DO_BUILD_DURING_DEPLOYMENT` | `0` | Disables Kudu server-side builds. |
| `WEBSITE_VNET_ROUTE_ALL` | `1` | Forces all outbound traffic into the VNet. |
| `APP_RELEASE_BUILDID` | `$(Build.BuildId)` | Custom tag for version auditing. |

---
