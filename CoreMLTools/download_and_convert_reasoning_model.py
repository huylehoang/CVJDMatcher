# download_and_convert_reasoning_model.py

import os
import torch
import numpy as np
import coremltools as ct
from transformers import AutoTokenizer, AutoModelForCausalLM

# === Config ===
MODEL_ID = "distilgpt2"
OUTPUT_DIR = "../CVJDMatcher/CoreMLModels"
MLPACKAGE_NAME = "ReasoningModel.mlpackage"
MAX_LENGTH = 128

print(f"🔍 Downloading reasoning model: {MODEL_ID}")
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
tokenizer.pad_token = tokenizer.eos_token  # fix padding issue

model = AutoModelForCausalLM.from_pretrained(MODEL_ID)
model.eval()

# === Step 1: Wrap model to return logits only
class ReasoningWrapper(torch.nn.Module):
    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, input_ids):
        return self.model(input_ids=input_ids).logits

wrapped_model = ReasoningWrapper(model)

# === Step 2: Dummy input for tracing
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

# === Step 3: Convert to Core ML
print("🔁 Converting to Core ML (.mlpackage)...")
mlmodel = ct.convert(
    traced,
    inputs=[ct.TensorType(name="input_ids", shape=input_ids.shape, dtype=np.int32)],
    convert_to="mlprogram",
    source="pytorch"
)

# === Step 4: Save model
mlpackage_path = os.path.join(OUTPUT_DIR, MLPACKAGE_NAME)
mlmodel.save(mlpackage_path)
print(f"✅ Saved model to {mlpackage_path}")
