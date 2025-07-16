#!/usr/bin/env bash
set -euo pipefail

# 📦 Model config
MODEL_REPO="google/gemma-2b-it-tflite"
MODEL_FILE="gemma-2b-it-cpu-int8.bin"
TARGET_NAME="gemma_2b_it_cpu_int8.bin"
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
  -o "${DEST_DIR}/${TARGET_NAME}"

# ✅ Verify
if [[ -f "${DEST_DIR}/${TARGET_NAME}" ]]; then
  echo "✅ Model saved to ${DEST_DIR}/${TARGET_NAME}"
else
  echo "❌ Failed to download $TARGET_NAME"
  exit 2
fi
