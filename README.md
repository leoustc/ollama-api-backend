# Ollama OpenAI-Compatible API Server

A production-ready OpenAI-compatible API server powered by Ollama models with secure authentication.

# Dependence

```bash
sudo apt-get install jq
```

## ✨ Features

- OpenAI-compatible `/v1/chat/completions` endpoint
- Leverages existing Ollama models (no auto-downloads)
- Secure Bearer Token Authentication
- Systemd service integration for reliability
- One-click installation script
- Performance-optimized model caching
- Automatic secure token generation
- Comprehensive testing suite

## 🚀 Quick Start

### Installation

```bash
git clone https://github.com/leoustc/ollama-openai.git
cd ollama-openai
chmod +x install.sh
./install.sh
```

### Verify Service Status

```bash
sudo systemctl status ollama-openai
```

### Get Your API Token

```bash
cat .env | grep OLLAMA_BEARER_TOKEN
```

## 🧪 Testing

Run the automated test suite:

```bash
chmod +x test.sh
./test.sh
```

### Test Suite Overview

1. **API Health Check**
```bash
curl -X GET "http://localhost:5051/"
```

2. **Token Verification**
```bash
cat .env | grep OLLAMA_BEARER_TOKEN
```

3. **Chat Completion Test**
```bash
curl -X POST "http://localhost:5051/v1/chat/completions" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer your-token" \
     -d '{
           "model": "mistral",
           "messages": [{"role": "user", "content": "Hello!"}]
         }'
```

4. **Model Cache Update**
```bash
curl -X GET "http://localhost:5051/v1/models/update" \
     -H "Authorization: Bearer your-token"
```

5. **Security Validation**
```bash
curl -X POST "http://localhost:5051/v1/chat/completions" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer wrong-token" \
     -d '{
           "model": "mistral",
           "messages": [{"role": "user", "content": "Hello!"}]
         }'
```

## ⚙️ Service Management

```bash
# Restart service
sudo systemctl restart ollama-openai

# Stop service
sudo systemctl stop ollama-openai

# Enable on boot
sudo systemctl enable ollama-openai
```

## 📋 Logging

Monitor real-time logs:

```bash
journalctl -u ollama-openai -f
```

## 🔍 Example Responses

### Health Check
```json
{
  "message": "Ollama OpenAI-compatible API is running!"
}
```

### Model Cache Update
```json
{
  "message": "Model cache updated",
  "models": ["mistral", "gemma", "llama2"]
}
```

### Chat Completion
```json
{
  "choices": [
    {
      "message": "Hello! How can I assist you today?"
    }
  ]
}
```

### Authentication Error
```json
{
  "detail": "Invalid Bearer Token"
}
