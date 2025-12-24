__init__.py
import azure.functions as func
from .handler import handle_request

def main(req: func.HttpRequest) -> func.HttpResponse:
    return handle_request(req)
handler.py
import azure.functions as func
from .service import say_hello

def handle_request(req: func.HttpRequest) -> func.HttpResponse:
    name = req.params.get("name")

    if not name:
        try:
            body = req.get_json()
            name = body.get("name")
        except ValueError:
            name = None

    result = say_hello(name)

    return func.HttpResponse(
        result,
        status_code=200,
        mimetype="text/plain"
    )
service.py
def say_hello(name: str | None) -> str:
    if not name:
        name = "World"
    return f"Hello, {name}!"

{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get"],
      "route": "hello"
    },
    {
      "type": "http",
      "direction": "out",
      "name": "$return"
    }
  ]
}
