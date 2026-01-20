```
azure-functions
azure-identity
azure-storage-blob

```
requirements.txt
init.py
```
import json
import logging
import azure.functions as func

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Read test.json from Blob Storage")

    # === 配置项（建议后续改成 App Settings）===
    storage_account_name = "mystorageprod01"
    container_name = "my-container"
    blob_name = "test.json"

    try:
        # 使用 Managed Identity
        credential = DefaultAzureCredential()

        account_url = f"https://{storage_account_name}.blob.core.windows.net"
        blob_service_client = BlobServiceClient(
            account_url=account_url,
            credential=credential
        )

        blob_client = blob_service_client.get_blob_client(
            container=container_name,
            blob=blob_name
        )

        # 读取 blob 内容
        blob_data = blob_client.download_blob().readall()

        # 假设 test.json 是标准 JSON
        content = json.loads(blob_data)

        return func.HttpResponse(
            json.dumps(content, ensure_ascii=False, indent=2),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logging.exception("Failed to read blob")
        return func.HttpResponse(
            f"Error reading blob: {str(e)}",
            status_code=500
        )


```
host
```
{
  "version": "2.0",
  "functionTimeout": "00:05:00",
  "logging": {
    "logLevel": {
      "default": "Information",
      "Function": "Information",
      "Host": "Warning"
    },
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true
      }
    }
  },
  "extensions": {
    "http": {
      "routePrefix": "api"
    }
  }
}

```
function.json
```
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "$return"
    }
  ]
}

```
