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