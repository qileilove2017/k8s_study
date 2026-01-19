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
