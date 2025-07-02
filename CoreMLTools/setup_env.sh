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

# === Run embedding model conversion ===
EMBED_MODEL="../CVJDMatcher/CoreMLModels/MiniLM/EmbeddingModel.mlpackage"
if [ -d "$EMBED_MODEL" ]; then
    echo "✅ $EMBED_MODEL already exists. Skipping download and conversion."
else
    echo "🚀 Running embedding model conversion script..."
    if python download_and_convert_embedding_model.py; then
        echo "🎉 Done: Embedding model saved at $EMBED_MODEL"
    else
        echo "❌ Embedding model conversion failed"
        exit 1
    fi
fi

# === Run reasoning model conversion ===
REASONING_MODEL="../CVJDMatcher/CoreMLModels/GPT2/ReasoningModel.mlpackage"
if [ -d "$REASONING_MODEL" ]; then
    echo "✅ $REASONING_MODEL already exists. Skipping download and conversion."
else
    echo "🚀 Running reasoning model conversion script..."
    if python download_and_convert_reasoning_model.py; then
        echo "🎉 Done: Reasoning model saved at $REASONING_MODEL"
    else
        echo "❌ Reasoning model conversion failed"
        exit 1
    fi
fi

# === Cleanup virtual env ===
echo "🧹 Cleaning up virtual environment..."
deactivate
rm -rf "$VENV_DIR"
echo "✅ Done."
