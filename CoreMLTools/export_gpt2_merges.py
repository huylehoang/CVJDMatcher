# export_gpt2_merges.py

import os
import json
import urllib.request

# === Config ===
OUTPUT_DIR = "../CVJDMatcher/CoreMLModels"
MERGES_JSON_PATH = os.path.join(OUTPUT_DIR, "GPT2Merges.json")
MERGES_URL = "https://huggingface.co/distilgpt2/resolve/main/merges.txt"

print("📥 Downloading merges.txt from HuggingFace...")
response = urllib.request.urlopen(MERGES_URL)
lines = response.read().decode("utf-8").splitlines()

merges = []
for line in lines:
    if line.startswith("#") or not line.strip():
        continue
    parts = line.strip().split()
    if len(parts) == 2:
        merges.append([parts[0], parts[1]])

print("💾 Saving merges.json...")
with open(MERGES_JSON_PATH, "w", encoding="utf-8") as f:
    json.dump(merges, f, indent=2, ensure_ascii=False)

print(f"✅ Saved merges to {MERGES_JSON_PATH}")
