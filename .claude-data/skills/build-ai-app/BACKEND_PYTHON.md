# Backend AI: Python/FastAPI (Cloudflare Containers Only)

> **WARNING**: Python + `google-genai` SDK does NOT work on Cloudflare Python Workers (exceeds 1000ms CPU startup limit). Use Cloudflare Containers instead. See skill `deploy-backend-to-cloudflare-containers`.

## AI Client with Dual-Environment Auth

```python
import os
from google import genai
from google.genai import types

AI_ENDPOINT = "https://studio-api.nxcode.io/api/ai-gateway"

def get_ai_client(request_headers: dict = None) -> genai.Client:
    """Create AI client with proper authentication for both dev and production."""
    headers = {}

    app_id = os.environ.get("NXCODE_APP_ID", "")
    workspace_id = os.environ.get("THREAD_ID", "")

    if app_id:
        # Production: deployed to Cloudflare Containers
        headers["X-App-Id"] = app_id
        if request_headers:
            auth = request_headers.get("Authorization", "")
            if auth:
                headers["Authorization"] = auth
    elif workspace_id:
        # Development: running in Nxcode workspace container
        headers["X-Workspace-Id"] = workspace_id
        if request_headers:
            session_token = request_headers.get("X-Session-Token", "")
            if session_token:
                headers["X-Session-Token"] = session_token

    return genai.Client(
        api_key="nxcode",  # Placeholder, gateway handles auth
        http_options={
            "api_endpoint": AI_ENDPOINT,
            "headers": headers
        }
    )
```

## FastAPI Integration

```python
from fastapi import FastAPI, Request
from pydantic import BaseModel

app = FastAPI()

class ChatRequest(BaseModel):
    message: str

@app.post("/api/chat")
async def chat(body: ChatRequest, request: Request):
    client = get_ai_client(dict(request.headers))
    response = client.models.generate_content(
        model="fast",
        contents=body.message
    )
    return {"reply": response.text}
```

## Streaming

```python
from fastapi.responses import StreamingResponse

@app.post("/api/chat/stream")
async def chat_stream(body: ChatRequest, request: Request):
    client = get_ai_client(dict(request.headers))

    def generate():
        for chunk in client.models.generate_content_stream(
            model="fast",
            contents=body.message
        ):
            if chunk.text:
                yield f"data: {chunk.text}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")
```

## Chatbot with History

```python
class Chatbot:
    def __init__(self, system_prompt: str = "You are a helpful assistant"):
        self.system_prompt = system_prompt
        self.history = []

    def chat(self, user_input: str, request_headers: dict = None) -> str:
        client = get_ai_client(request_headers)
        self.history.append({"role": "user", "parts": [{"text": user_input}]})

        response = client.models.generate_content(
            model="fast",
            contents=self.history,
            config=types.GenerateContentConfig(
                system_instruction=self.system_prompt
            )
        )

        assistant_message = response.text
        self.history.append({"role": "model", "parts": [{"text": assistant_message}]})
        return assistant_message
```

## JSON Output

```python
import json

def get_structured_response(prompt: str, request_headers: dict = None) -> dict:
    client = get_ai_client(request_headers)
    response = client.models.generate_content(
        model="fast",
        contents=f"Respond with valid JSON only. {prompt}",
        config=types.GenerateContentConfig(
            response_mime_type="application/json"
        )
    )
    return json.loads(response.text)
```

## After Deployment: Set NXCODE_APP_ID

```bash
# Get app_id from the deploy output JSON
nxcode secret set my-api NXCODE_APP_ID "deploy_abc123def456"
```
