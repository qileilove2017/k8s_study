terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-blob-func-eh-private"
  location = "East Asia"
}

# 1. Network Infrastructure
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-private"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "snet_func" {
  name                 = "snet-func-integration"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "snet_pe" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 2. Private DNS Zones
resource "azurerm_private_dns_zone" "dns_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "dns_eh" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link_blob" {
  name                  = "link-blob"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "link_eh" {
  name                  = "link-eh"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_eh.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# 3. Storage Account (Locked down)
resource "azurerm_storage_account" "st" {
  name                     = "stprivfunc${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false # Deny public access
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_container" "input_container" {
  name                  = "input-json"
  storage_account_name  = azurerm_storage_account.st.name
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "pe_blob" {
  name                = "pe-blob"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.snet_pe.id

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.st.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-group-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_blob.id]
  }
}

# 4. Event Hub Namespace (Locked down)
resource "azurerm_eventhub_namespace" "ehns" {
  name                = "ehns-priv-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 1
  public_network_access_enabled = false
}

resource "azurerm_eventhub" "eh" {
  name                = "eh-output"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_authorization_rule" "eh_auth" {
  name                = "eh-function-auth"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  eventhub_name       = azurerm_eventhub.eh.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = false
  send                = true
  manage              = false
}

resource "azurerm_private_endpoint" "pe_eh" {
  name                = "pe-eh"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.snet_pe.id

  private_service_connection {
    name                           = "psc-eh"
    private_connection_resource_id = azurerm_eventhub_namespace.ehns.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-group-eh"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_eh.id]
  }
}

# 5. Azure Function App (Premium Plan for VNet Integration)
resource "azurerm_service_plan" "plan" {
  name                = "asp-premium"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "EP1" # Required for VNet Integration
}

resource "azurerm_linux_function_app" "func" {
  name                = "func-priv-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.st.name
  storage_account_access_key = azurerm_storage_account.st.primary_access_key
  
  # Connect Function to VNet
  virtual_network_subnet_id = azurerm_subnet.snet_func.id

  app_settings = {
    "AzureWebJobsStorage" = azurerm_storage_account.st.primary_connection_string
    
    # 强制 Function 通过 VNet 访问 Storage
    "WEBSITE_CONTENTOVERVNET" = "1" 
    "WEBSITE_VNET_ROUTE_ALL"  = "1"
    "WEBSITE_DNS_SERVER"      = "168.63.129.16" # Azure DNS

    "STORAGE_CONNECTION_STRING_FUNC" = azurerm_storage_account.st.primary_connection_string
    "EVENT_HUB_CONNECTION_STR"       = azurerm_eventhub_authorization_rule.eh_auth.primary_connection_string
    "EVENT_HUB_NAME"                 = azurerm_eventhub.eh.name
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }
}

output "storage_connection_string" {
  value     = azurerm_storage_account.st.primary_connection_string
  sensitive = true
}

output "event_hub_connection_string" {
  value     = azurerm_eventhub_authorization_rule.eh_auth.primary_connection_string
  sensitive = true
}

output "function_app_name" {
  value = azurerm_linux_function_app.func.name
}
