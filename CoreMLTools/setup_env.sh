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
EMBED_MODEL="../CVJDMatcher/CoreMLModels/EmbeddingModel.mlpackage"
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

# === Export MiniLM vocab ===
VOCAB_MINILM="../CVJDMatcher/CoreMLModels/MiniLMVocab.json"
if [ -f "$VOCAB_MINILM" ]; then
    echo "✅ $VOCAB_MINILM already exists. Skipping export."
else
    echo "🧠 Exporting MiniLM vocab..."
    if python export_minilm_vocab.py; then
        echo "🎉 Done: MiniLM vocab saved at $VOCAB_MINILM"
    else
        echo "❌ Failed to export MiniLM vocab"
        exit 1
    fi
fi

# === Run reasoning model conversion ===
REASONING_MODEL="../CVJDMatcher/CoreMLModels/ReasoningModel.mlpackage"
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

# === Export GPT-2 vocab ===
VOCAB_GPT2="../CVJDMatcher/CoreMLModels/GPT2Vocab.json"
if [ -f "$VOCAB_GPT2" ]; then
    echo "✅ $VOCAB_GPT2 already exists. Skipping export."
else
    echo "🧠 Exporting GPT-2 vocab..."
    if python export_gpt2_vocab.py; then
        echo "🎉 Done: GPT-2 vocab saved at $VOCAB_GPT2"
    else
        echo "❌ Failed to export GPT-2 vocab"
        exit 1
    fi
fi

# === Export GPT-2 merges ===
MERGES_GPT2="../CVJDMatcher/CoreMLModels/GPT2Merges.json"
if [ -f "$MERGES_GPT2" ]; then
    echo "✅ $MERGES_GPT2 already exists. Skipping export."
else
    echo "🧠 Exporting GPT-2 merges..."
    if python export_gpt2_merges.py; then
        echo "🎉 Done: GPT-2 merges saved at $MERGES_GPT2"
    else
        echo "❌ Failed to export GPT-2 merges"
        exit 1
    fi
fi

# === Cleanup virtual env ===
echo "🧹 Cleaning up virtual environment..."
deactivate
rm -rf "$VENV_DIR"
echo "✅ Done."
