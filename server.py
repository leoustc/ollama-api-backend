import os
from fastapi import FastAPI, HTTPException, Security, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import ollama
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = FastAPI()

# Retrieve Bearer Token from .env
BEARER_TOKEN = os.getenv("OLLAMA_BEARER_TOKEN")
if not BEARER_TOKEN:
    raise RuntimeError("❌ OLLAMA_BEARER_TOKEN is missing from .env. Please run install.sh.")

# Security for Bearer Token authentication
security = HTTPBearer()

# Cache available models
MODEL_CACHE = []

def update_model_cache():
    """Updates the cached list of available models in Ollama."""
    global MODEL_CACHE
    MODEL_CACHE = [model["model"] for model in ollama.list()["models"]]

# Initial cache population
update_model_cache()

# OpenAI-Compatible Request Format
class OpenAIRequest(BaseModel):
    model: str
    messages: list

# Function to verify Bearer Token
def verify_bearer_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    if token != BEARER_TOKEN:
        raise HTTPException(status_code=403, detail="Invalid Bearer Token")

# Function to get the first available model
def get_existing_model():
    """Returns the first available model from the cache."""
    return MODEL_CACHE[0] if MODEL_CACHE else None

@app.post("/v1/chat/completions", dependencies=[Depends(verify_bearer_token)])
async def chat_completions(request: OpenAIRequest):
    """Handles chat completions using Ollama models."""
    
    if request.model not in MODEL_CACHE:
        update_model_cache()  # Refresh cache in case models have changed
        if request.model not in MODEL_CACHE:
            request.model = get_existing_model()
            if not request.model:
                raise HTTPException(status_code=404, detail="No Ollama models available on the system.")
            
            print(f"⚠️ Model '{request.model}' not found. Using '{request.model}' instead.")

    # Generate response
    response = ollama.chat(model=request.model, messages=request.messages)
    return {"choices": [{"message": response['message']}]}

# Health Check Endpoint
@app.get("/")
async def root():
    return {"message": "Ollama OpenAI-compatible API is running!"}

# Endpoint to refresh model cache manually
@app.get("/v1/models/update", dependencies=[Depends(verify_bearer_token)])
async def refresh_models():
    update_model_cache()
    return {"message": "Model cache updated", "models": MODEL_CACHE}

if __name__ == "__main__":
    import uvicorn
    print(f"✅ Loaded Bearer Token: {BEARER_TOKEN}")  # Debugging (remove in production)
    print(f"✅ Initial available models: {MODEL_CACHE}")
    uvicorn.run(app, host="0.0.0.0", port=5051)
