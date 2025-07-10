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

# === Run all-MiniLM-L6-v2  model conversion ===
echo "🚀 Running all-MiniLM-L6-v2 model conversion script..."
if python download_and_convert_mini_lm_model.py; then
    echo "🎉 Done: Mini_LM model saved"
else
    echo "❌ Embedding model conversion failed"
    exit 1
fi

# === Run Llama2 model conversion ===
echo "🚀 Running Llama2 model conversion script..."
if python download_and_convert_llama2_model.py; then
    echo "🎉 Done: Llama2 model saved"
else
    echo "❌ Llama2 model conversion failed"
    exit 1
fi

# === Run TinyLlama model conversion ===
echo "🚀 Running TinyLlama model conversion script..."
if python download_and_convert_tiny_llama_model.py; then
    echo "🎉 Done: TinyLlama model saved"
else
    echo "❌ TinyLlama model conversion failed"
    exit 1
fi

# === Cleanup virtual env ===
echo "🧹 Cleaning up virtual environment..."
deactivate
rm -rf "$VENV_DIR"
echo "✅ Done."
