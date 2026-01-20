```
import os
import json
import time
from azure.storage.blob import BlobServiceClient

# 配置
# 生产环境请使用环境变量
CONNECTION_STRING = os.environ.get("STORAGE_CONNECTION_STRING", "DefaultEndpointsProtocol=https;AccountName=<ACCOUNT_NAME>;AccountKey=<KEY>;EndpointSuffix=core.windows.net")
CONTAINER_NAME = "input-json"
BLOB_NAME = f"data-{int(time.time())}.json"

def run():
    # 1. 连接 Storage
    try:
        blob_service_client = BlobServiceClient.from_connection_string(CONNECTION_STRING)
        
        # 2. 创建容器 (如果不存在)
        container_client = blob_service_client.get_container_client(CONTAINER_NAME)
        if not container_client.exists():
            container_client.create_container()
            print(f"Container '{CONTAINER_NAME}' created.")

        # 3. 准备 JSON 数据
        data = {
            "id": 1,
            "message": "Original Message",
            "timestamp": time.time(),
            "status": "new"
        }
        json_content = json.dumps(data)
        
        # 4. 上传
        print(f"Uploading JSON to {CONTAINER_NAME}/{BLOB_NAME}...")
        blob_client = container_client.get_blob_client(blob=BLOB_NAME)
        blob_client.upload_blob(json_content, overwrite=True)
        print("Upload success.")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    run()
```

function
```
import azure.functions as func
import logging
import json
import os

app = func.FunctionApp()

# Blob Trigger: 监听 input-json 容器中的所有 blob
# Event Hub Output: 处理完后发送到 Event Hub
@app.blob_trigger(arg_name="myblob", path="input-json/{name}",
                  connection="STORAGE_CONNECTION_STRING_FUNC")
@app.event_hub_output(arg_name="outputhub",
                      event_hub_name="<EVENT_HUB_NAME>",
                      connection="EVENT_HUB_CONNECTION_STR")
def blob_process_func(myblob: func.InputStream, outputhub: func.Out[str]):
    logging.info(f"Python Blob trigger function processed blob \n"
                 f"Name: {myblob.name} \n"
                 f"Blob Size: {myblob.length} bytes")

    try:
        # 1. 读取 Blob 内容 (JSON)
        blob_content = myblob.read().decode("utf-8")
        json_data = json.loads(blob_content)
        
        logging.info(f"Original Data: {json_data}")

        # 2. 修改值
        if "status" in json_data:
            json_data["status"] = "processed"
        
        json_data["processed_by"] = "Azure Function"
        json_data["processed_time"] = "now" # In real app use datetime

        modified_content = json.dumps(json_data)
        logging.info(f"Modified Data: {modified_content}")

        # 3. 转发到 Azure Event Hub
        # 通过 Output Binding 直接设值即可
        outputhub.set(modified_content)
        
    except Exception as e:
        logging.error(f"Error processing blob: {e}")
        # 这里可以选择不抛出异常，或者将错误信息发送到死信队列

```
host
```
{
    "version": "2.0",
    "logging": {
        "applicationInsights": {
            "samplingSettings": {
                "isEnabled": true,
                "excludedTypes": "Request"
            }
        }
    },
    "extensionBundle": {
        "id": "Microsoft.Azure.Functions.ExtensionBundle",
        "version": "[4.*, 5.0.0)"
    }
}
```
local.settings.json
```
{
    "IsEncrypted": false,
    "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "python",
        "STORAGE_CONNECTION_STRING_FUNC": "YourBlobStorageConnectionStringHere",
        "EVENT_HUB_CONNECTION_STR": "YourEventHubConnectionStringHere",
        "EVENT_HUB_NAME": "YourEventHubName"
    }
}
```

requirements.txt
```
azure-functions
azure-storage-blob
azure-eventhub

```
tf 改进
```
# --- 1. 存储账户配置 ---
resource "azurerm_storage_account" "st" {
  name                     = "stinternalprod001"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # 禁用共享密钥，强制使用 Entra ID
  shared_access_key_enabled = false
  
  # 限制公网访问
  public_network_access_enabled = false 

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# --- 2. Function App 配置 ---
resource "azurerm_linux_function_app" "func" {
  name                = "fn-blob-processor-prod"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.st.name
  # 虽然禁用了 Key，但 TF 部署初期可能需要此 Key 建立连接，建议保留引用
  storage_account_access_key = azurerm_storage_account.st.primary_access_key

  # 开启 VNet 集成
  virtual_network_subnet_id = azurerm_subnet.func_subnet.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    vnet_route_all_enabled = true # 关键：确保所有流量走内网
    application_stack {
      python_version = "3.9"
    }
  }

  app_settings = {
    # 内部运行依赖存储（基于身份）
    "AzureWebJobsStorage__accountName" = azurerm_storage_account.st.name
    "AzureWebJobsStorage__credential"  = "managedidentity"

    # 业务 Trigger 连接配置
    "MyStorageConfig__accountName"    = azurerm_storage_account.st.name
    "MyStorageConfig__blobServiceUri" = azurerm_storage_account.st.primary_blob_endpoint
    "MyStorageConfig__credential"     = "managedidentity"
    
    # 禁用 Function 的公网文件系统访问（可选，进一步加固）
    "WEBSITE_CONTENTOVERVNET" = "1"
  }
}

# --- 3. 权限分配 (IAM) ---
# 必须：Blob 数据权限
resource "azurerm_role_assignment" "st_blob_data_owner" {
  scope                = azurerm_storage_account.st.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_linux_function_app.func.identity[0].principal_id
}

# 必须：Queue 权限（支持 Blob Trigger 扩展）
resource "azurerm_role_assignment" "st_queue_data" {
  scope                = azurerm_storage_account.st.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_linux_function_app.func.identity[0].principal_id
}
```
python
```
import logging
import azure.functions as func

# connection="MyStorageConfig" 对应上面环境变量的前缀
@app.blob_trigger(arg_name="myblob", path="input-container/{name}",
                  connection="MyStorageConfig") 
def blob_trigger_function(myblob: func.InputStream):
    logging.info(f"Python blob trigger function processed blob \n"
                 f"Name: {myblob.name}\n"
                 f"Blob Size: {myblob.length} bytes")
    
    # 直接读取内容
    content = myblob.read().decode('utf-8')
    logging.info(f"Content: {content}")
```
code 2
```
import azure.functions as func
import logging

app = func.FunctionApp()

@app.blob_trigger(arg_name="myblob", 
                  path="input-container/{name}",
                  connection="MyStorageConfig") # 对应你在 TF 中设置的环境变量前缀
def test_function(myblob: func.InputStream):
    # 此时 myblob 已经是已经打开的数据流，直接读取即可
    blob_content = myblob.read().decode('utf-8')
    logging.info(f"成功读取到文件，内容长度为: {len(blob_content)}")
```