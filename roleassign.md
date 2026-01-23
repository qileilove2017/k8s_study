main.tf
```
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = each.value.scope_id
  role_definition_name = try(each.value.role_definition_name, null)
  role_definition_id   = try(each.value.role_definition_id, null)
  principal_id         = each.value.principal_id
  
  description          = try(each.value.description, "Created by Terraform module")
  
  # Optional: Management of skip_service_principal_aad_check is often useful for new SPs
  skip_service_principal_aad_check = try(each.value.skip_service_principal_aad_check, false)
}
```
outputs.tf
```
output "role_assignment_ids" {
  description = "The IDs of the role assignments created."
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
}

output "role_assignment_principals" {
  description = "The Principal IDs of the role assignments created."
  value       = { for k, v in azurerm_role_assignment.this : k => v.principal_id }
}

```
README.md
```
# Azure Role Assignment Module Usage

This module allows you to manage Azure Role Assignments (IAM) flexibly across your organization.

## Usage

```hcl
module "iam_assignments" {
  source = "./share_module/azure_role_assignment"

  role_assignments = {
    # Example 1: Assign 'Contributor' to a User on a Resource Group
    "dev_user_rg_contributor" = {
        scope_id             = azurerm_resource_group.example.id
        principal_id         = "00000000-0000-0000-0000-000000000000" # Object ID of User/Group
        role_definition_name = "Contributor"
    },
    
    # Example 2: Assign 'Storage Blob Data Owner' to a Managed Identity on a Storage Account
    "app_storage_owner" = {
        scope_id             = azurerm_storage_account.example.id
        principal_id         = azurerm_linux_function_app.example.identity[0].principal_id
        role_definition_name = "Storage Blob Data Owner"
        skip_service_principal_aad_check = true # Good for new MSI
    },
    
    # Example 3: Assign a Custom Role ID
    "custom_role_assignment" = {
        scope_id           = azurerm_resource_group.example.id
        principal_id       = "11111111-1111-1111-1111-111111111111"
        role_definition_id = "/subscriptions/0000.../providers/Microsoft.Authorization/roleDefinitions/..."
    }
  }
}
```

## Inputs

| Name | Type | Description |
|------|------|-------------|
| role_assignments | map(object) | A map of assignment definitions. |

Each object in `role_assignments` supports:
- `scope_id`: (Required) The target resource ID.
- `principal_id`: (Required) The object ID of the user/group/SPN.
- `role_definition_name`: name of built-in role.
- `role_definition_id`: full ID of custom/built-in role (alternative to name).

```
variables.tf
```
variable "role_assignments" {
  description = <<EOT
  A map of role assignments to create. The key is a unique identifier for the assignment (e.g., 'user1-reader-rg1'). 
  The value is an object with the following attributes:
  - scope_id: The ID of the Scope (Subscription, RG, or Resource) to assign the role on.
  - principal_id: The ID of the Principal (User, Group, SPN, Identity) to assign the role to.
  - role_definition_name: (Optional) The name of the Built-in Role (e.g., 'Contributor', 'Storage Blob Data Owner').
  - role_definition_id: (Optional) The ID of a Custom Role. One of 'role_definition_name' or 'role_definition_id' must be provided.
  - description: (Optional) Description of the assignment.
  - skip_service_principal_aad_check: (Optional) If true, skips the AAD check for the service principal. Useful when the SP is recently created. Default is false.
  EOT
  
  type = map(object({
    scope_id                         = string
    principal_id                     = string
    role_definition_name             = optional(string)
    role_definition_id               = optional(string)
    description                      = optional(string)
    skip_service_principal_aad_check = optional(bool)
  }))
}

```