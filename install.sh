#!/bin/bash

set -e  # Exit on error

# Define paths based on current directory
APP_DIR=$(pwd)
SERVICE_FILE="/etc/systemd/system/ollama-openai.service"
ENV_FILE="$APP_DIR/.env"

# Check for dry run mode
DRYRUN=false
if [ "$1" == "dryrun" ]; then
    DRYRUN=true
    echo "🟢 Running in DRY RUN mode: The server will run in the foreground."
fi

echo "📦 Installing dependencies..."
sudo apt update && sudo apt install -y python3 python3-pip python3-venv curl

echo "🐍 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install fastapi uvicorn pydantic requests python-dotenv ollama

echo "⚙️ Creating .env file (if missing)..."
if [ ! -f "$ENV_FILE" ]; then
    RANDOM_KEY="ol-"$(openssl rand -hex 32)
    echo "OLLAMA_BEARER_TOKEN=$RANDOM_KEY" > $ENV_FILE
    echo "✅ Generated random API token: $RANDOM_KEY"
else
    echo "✅ .env file already exists."
fi

if [ "$DRYRUN" = true ]; then
    echo "🚀 Starting Ollama OpenAI server in foreground mode..."
    python server.py
    exit 0
fi

echo "🔄 Setting up systemd service..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Ollama OpenAI-Compatible API Server
After=network.target

[Service]
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python $APP_DIR/server.py
Environment=PYTHONUNBUFFERED=1
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reloading systemd and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable ollama-openai
sudo systemctl restart ollama-openai

echo "✅ Installation complete! Server is running at http://localhost:5051"

sudo systemctl status ollama-openai
