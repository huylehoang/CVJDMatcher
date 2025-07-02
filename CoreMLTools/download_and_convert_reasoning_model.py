import os
import torch
import numpy as np
import coremltools as ct
from transformers import AutoTokenizer, AutoModelForCausalLM
from pathlib import Path

# === Config ===
MODEL_ID = "distilgpt2"
OUTPUT_DIR = "../CVJDMatcher/CoreMLModels/GPT2"
TOKENIZER_DIR = os.path.join(OUTPUT_DIR, "GPT2Tokenizer")
MLPACKAGE_NAME = "ReasoningModel.mlpackage"
MAX_LENGTH = 128

# === Step 1: Download model
print(f"🔍 Downloading reasoning model: {MODEL_ID}")
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
tokenizer.pad_token = tokenizer.eos_token  # Fix padding issue

model = AutoModelForCausalLM.from_pretrained(MODEL_ID)
model.eval()

# === Step 2: Wrap model to return logits only
class ReasoningWrapper(torch.nn.Module):
    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, input_ids):
        return self.model(input_ids=input_ids).logits

wrapped_model = ReasoningWrapper(model)

# === Step 3: Dummy input for tracing
sample_text = "This CV matches because"
tokens = tokenizer(
    sample_text,
    return_tensors="pt",
    padding="max_length",
    max_length=MAX_LENGTH,
    truncation=True
)
input_ids = tokens["input_ids"]

print("📦 Tracing model...")
with torch.no_grad():
    traced = torch.jit.trace(wrapped_model, input_ids, strict=False)

# === Step 4: Convert to Core ML
print("🔁 Converting to Core ML (.mlpackage)...")
mlmodel = ct.convert(
    traced,
    inputs=[ct.TensorType(name="input_ids", shape=input_ids.shape, dtype=np.int32)],
    convert_to="mlprogram",
    source="pytorch"
)

# === Step 5: Save model
mlpackage_path = os.path.join(OUTPUT_DIR, MLPACKAGE_NAME)
os.makedirs(OUTPUT_DIR, exist_ok=True)
mlmodel.save(mlpackage_path)
print(f"✅ Saved model to {mlpackage_path}")

# === Step 6: Save and rename tokenizer files
print("📥 Downloading tokenizer...")
tokenizer_path = Path(TOKENIZER_DIR)
tokenizer_path.mkdir(parents=True, exist_ok=True)
tokenizer.save_pretrained(str(tokenizer_path))

rename_targets = [
    "tokenizer.json",
    "tokenizer_config.json",
    "vocab.json",
    "merges.txt",
    "special_tokens_map.json",
    "added_tokens.json"
]

for filename in rename_targets:
    original = tokenizer_path / filename
    renamed = tokenizer_path / f"gpt2_{filename}"
    if original.exists():
        original.rename(renamed)
        print(f"✅ Renamed {filename} → gpt2_{filename}")

final_tokenizer_path = tokenizer_path / "gpt2_tokenizer.json"
if final_tokenizer_path.exists():
    print(f"🎉 Done: GPT-2 tokenizer saved at {final_tokenizer_path.resolve()}")
else:
    print("❌ Failed to save tokenizer.json.")
