# export_minilm_vocab.py

import os
import json
from transformers import AutoTokenizer

# === CONFIGURATION ===
MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"
OUTPUT_DIR = "../CVJDMatcher/CoreMLModels"
VOCAB_JSON_FILENAME = "MiniLMVocab.json"

# === STEP 1: Load tokenizer
print(f"📥 Loading tokenizer from HuggingFace: {MODEL_ID}")
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)

# === STEP 2: Export vocab
print("📄 Exporting vocab to JSON format...")
vocab = tokenizer.get_vocab()

# Sort vocab by ID to preserve ordering
vocab = dict(sorted(vocab.items(), key=lambda item: item[1]))

# === STEP 3: Save vocab file
vocab_path = os.path.join(OUTPUT_DIR, VOCAB_JSON_FILENAME)
with open(vocab_path, "w", encoding="utf-8") as f:
    json.dump(vocab, f, indent=2, ensure_ascii=False)

print(f"✅ Saved vocab to {vocab_path}")
