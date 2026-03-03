#!/bin/bash

set -e

OLLAMA_MODELS_PATH="/mnt/0CD64552D6453CE8"
SERVICE_FILE="/etc/systemd/system/ollama.service"
BACKUP_FILE="/etc/systemd/system/ollama.service.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Ollama USB SSD Configuration Script"
echo "======================================"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script requires sudo privileges"
    echo "Please run: sudo bash $0"
    exit 1
fi

# Check if USB SSD path exists
if [ ! -d "$OLLAMA_MODELS_PATH" ]; then
    echo "❌ Error: Models path does not exist: $OLLAMA_MODELS_PATH"
    echo "Please ensure your USB SSD is mounted"
    exit 1
fi

echo "✅ USB SSD models directory found"

# Check if ollama service file exists
if [ ! -f "$SERVICE_FILE" ]; then
    echo "❌ Error: Ollama service file not found: $SERVICE_FILE"
    exit 1
fi

echo "✅ Ollama service file found"

# Create backup
echo "📋 Creating backup: $BACKUP_FILE"
cp "$SERVICE_FILE" "$BACKUP_FILE"

# Check if OLLAMA_MODELS is already configured
if grep -q "OLLAMA_MODELS" "$SERVICE_FILE"; then
    echo "⚠️  OLLAMA_MODELS environment variable already exists in service file"
    echo "Current configuration:"
    grep "OLLAMA_MODELS" "$SERVICE_FILE"
    echo ""
    read -p "Do you want to update it? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Configuration cancelled"
        exit 0
    fi

    # Remove existing OLLAMA_MODELS line
    sed -i '/Environment="OLLAMA_MODELS/d' "$SERVICE_FILE"
fi

# Add OLLAMA_MODELS environment variable after the PATH line
sed -i '/^Environment="PATH=/a Environment="OLLAMA_MODELS='"$OLLAMA_MODELS_PATH"'"' "$SERVICE_FILE"

echo "✅ Added OLLAMA_MODELS environment variable"

# Reload systemd
echo "🔄 Reloading systemd daemon..."
systemctl daemon-reload

# Restart ollama service
echo "🔄 Restarting ollama service..."
systemctl restart ollama

# Wait a moment for service to start
sleep 2

# Check service status
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama service is running"
else
    echo "⚠️  Ollama service may not have started correctly"
    systemctl status ollama --no-pager
    exit 1
fi

echo ""
echo "======================================"
echo "✨ Configuration complete!"
echo "======================================"
echo ""
echo "📍 Models location: $OLLAMA_MODELS_PATH"
echo "💾 Backup saved to: $BACKUP_FILE"
echo ""
echo "🔍 Checking available models..."
su - kaishraiberg -c "ollama list"
echo ""
echo "To verify the configuration:"
echo "  systemctl status ollama"
echo "  ollama list"
echo ""
