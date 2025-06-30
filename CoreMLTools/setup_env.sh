#!/bin/bash
set -e

# === Detect preferred Python ===
if [ -x "/opt/homebrew/opt/python@3.11/bin/python3.11" ]; then
  PYTHON_BIN="/opt/homebrew/opt/python@3.11/bin/python3.11"
  echo "🔍 Found preferred Python 3.11 at: $PYTHON_BIN"
else
  echo "❌ Python 3.11 not found."
  echo "👉 Please run: brew install python@3.11"
  exit 1
fi

PYTHON_VERSION=$($PYTHON_BIN -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "✅ Python version: $PYTHON_VERSION"

# === Setup virtual env ===
VENV_DIR="./venv"
if [ -d "$VENV_DIR" ]; then
    echo "🧹 Removing old venv..."
    rm -rf "$VENV_DIR"
fi

echo "📦 Creating virtual environment..."
$PYTHON_BIN -m venv "$VENV_DIR"

echo "✅ Activating venv..."
source "$VENV_DIR/bin/activate"

# === Install dependencies ===
pip install --upgrade pip > /dev/null

echo "📦 Installing requirements..."
pip install torch==2.5.0 transformers coremltools

# === Run scripts ===

# 1. download_and_convert_embedding_model.py
MLPACKAGE_NAME="../CVJDMatcher/CoreMLModels/EmbeddingModel.mlpackage"
if [ -d "$MLPACKAGE_NAME" ]; then
    echo "✅ $MLPACKAGE_NAME already exists. Skipping download and conversion."
else
    echo "🚀 Running conversion script..."
    if python download_and_convert_embedding_model.py; then
        echo "🎉 Done: Model saved at ./$MLPACKAGE_NAME"
    else
        echo "❌ Conversion failed"
        exit 1
    fi
fi

# 2. download_and_convert_reasoning_model.py
REASONING_MLPACKAGE_NAME="../CVJDMatcher/CoreMLModels/ReasoningModel.mlpackage"
if [ -d "$REASONING_MLPACKAGE_NAME" ]; then
    echo "✅ $REASONING_MLPACKAGE_NAME already exists. Skipping download and conversion."
else
    echo "🚀 Running reasoning model conversion script..."
    if python download_and_convert_reasoning_model.py; then
        echo "🎉 Done: Reasoning model saved at ./$REASONING_MLPACKAGE_NAME"
    else
        echo "❌ Reasoning model conversion failed"
        exit 1
    fi
fi

# Clean up
echo "🧹 Cleaning up virtual environment..."
rm -rf venv
