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
