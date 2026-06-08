#!/bin/bash

echo "🚀 Starting OpenNote Application..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed. Please install Python 3.8+"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter SDK"
    exit 1
fi

# Install Python dependencies
echo "📦 Installing Python dependencies..."
cd embedding_service
pip3 install -r requirements.txt
cd ..

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Start Python service in background
echo "🔧 Starting Python service..."
cd embedding_service
python3 main.py --port 8765 &
PYTHON_PID=$!
cd ..

# Wait for Python service to start
sleep 2

# Check if Python service is running
if curl -s http://localhost:8765/health > /dev/null 2>&1; then
    echo "✅ Python service is running on port 8765"
else
    echo "⚠️  Python service may not be running. You can start it manually: cd embedding_service && python3 main.py --port 8765"
fi

# Run Flutter app
echo "📱 Starting Flutter app..."
flutter run -d macos

# Cleanup when Flutter app closes
kill $PYTHON_PID 2>/dev/null

echo "👋 OpenNote Application stopped"