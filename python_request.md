```
azure-functions
azure-identity
azure-storage-blob

```
requirements.txt
function_app.py
```
import azure.functions as func
import logging
import json
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

@app.route(route="get_json_data")
def get_json_data(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('正在处理请求以获取存储中的 JSON 数据。')

    # 配置：建议生产环境通过环境变量获取
    # 例如：account_url = os.environ["STORAGE_ACCOUNT_URL"]
    account_url = "https://<你的存储账户名>.blob.core.windows.net"
    container_name = "test-container"
    blob_name = "test.json"

    try:
        # 1. 身份验证：无密钥访问的关键
        # 在 PE 环境下，这会通过 VNet 内部流量完成身份校验
        credential = DefaultAzureCredential()

        # 2. 建立客户端
        blob_service_client = BlobServiceClient(account_url, credential=credential)
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)

        # 3. 读取数据
        download_stream = blob_client.download_blob()
        content = download_stream.readall().decode('utf-8')
        json_data = json.loads(content)

        return func.HttpResponse(
            json.dumps(json_data),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logging.error(f"发生错误: {str(e)}")
        return func.HttpResponse(f"无法读取文件: {str(e)}", status_code=500)

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
