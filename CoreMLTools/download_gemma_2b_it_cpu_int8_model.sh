#!/usr/bin/env bash
set -euo pipefail

# 📦 Model config
MODEL_REPO="google/gemma-2b-it-tflite"
MODEL_FILE="gemma-2b-it-cpu-int8.bin"
DEST_DIR="../CVJDMatcher/CoreMLModels/Gemma"

# 🔐 Check for Hugging Face token
if [[ -z "${HF_TOKEN:-}" ]]; then
  echo "❌ HF_TOKEN is not set."
  echo "👉 Please export it first with:"
  echo "   export HF_TOKEN=hf_your_token_here"
  exit 1
fi

# 📁 Create destination folder
mkdir -p "$DEST_DIR"

# 🌐 Download model file using Hugging Face API
echo "📥 Downloading $MODEL_FILE from $MODEL_REPO..."
curl -L -H "Authorization: Bearer $HF_TOKEN" \
  "https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILE}" \
  -o "${DEST_DIR}/${MODEL_FILE}"

# ✅ Verify
if [[ -f "${DEST_DIR}/${MODEL_FILE}" ]]; then
  echo "✅ Model saved to ${DEST_DIR}/${MODEL_FILE}"
else
  echo "❌ Failed to download $MODEL_FILE"
  exit 2
fi
