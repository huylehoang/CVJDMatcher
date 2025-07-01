# export_gpt2_vocab.py

import os
import json
from transformers import AutoTokenizer

# === Config ===
MODEL_ID = "distilgpt2"
OUTPUT_DIR = "../CVJDMatcher/CoreMLModels"
VOCAB_JSON_PATH = os.path.join(OUTPUT_DIR, "GPT2Vocab.json")

print(f"📥 Loading tokenizer for: {MODEL_ID}")
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)

print("💾 Saving vocab.json...")
vocab = tokenizer.get_vocab()
vocab = dict(sorted(vocab.items(), key=lambda item: item[1]))  # sort by ID

with open(VOCAB_JSON_PATH, "w", encoding="utf-8") as f:
    json.dump(vocab, f, indent=2, ensure_ascii=False)

print(f"✅ Saved vocab to {VOCAB_JSON_PATH}")
