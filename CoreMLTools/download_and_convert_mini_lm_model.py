import os
import json
import torch
import numpy as np
import coremltools as ct
from transformers import AutoModel, AutoTokenizer

# === CONFIGURATION ===
MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"
OUTPUT_DIR = "../CVJDMatcher/CoreMLModels/MiniLM"
MLPACKAGE_NAME = "mini_lm.mlpackage"
VOCAB_JSON_FILENAME = "mini_lm_vocab.json"
MAX_LEN = 128

# === Ensure output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)

# === STEP 1: Load tokenizer + model ===
print(f"🔍 Downloading model from HuggingFace: {MODEL_ID}")
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
hf_model = AutoModel.from_pretrained(MODEL_ID)
hf_model.eval()
hf_model.requires_grad_(False)

# === STEP 2: Wrap model to return CLS token
class CLSModel(torch.nn.Module):
    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, input_ids: torch.Tensor, attention_mask: torch.Tensor) -> torch.Tensor:
        outputs = self.model(input_ids=input_ids, attention_mask=attention_mask)
        return outputs.last_hidden_state[:, 0]  # Use CLS token

wrapped_model = CLSModel(hf_model)

# === STEP 3: Trace with dummy input
input_ids = torch.randint(low=0, high=tokenizer.vocab_size, size=(1, MAX_LEN), dtype=torch.long)
attention_mask = torch.ones((1, MAX_LEN), dtype=torch.long)

print("📦 Tracing model...")
traced = torch.jit.trace(wrapped_model, (input_ids, attention_mask), strict=False)

# === STEP 4: Convert to Core ML
print("🔁 Converting to Core ML (.mlpackage)...")
mlmodel = ct.convert(
    traced,
    convert_to="mlprogram",
    source="pytorch",
    inputs=[
        ct.TensorType(name="input_ids", shape=(1, MAX_LEN), dtype=np.int64),
        ct.TensorType(name="attention_mask", shape=(1, MAX_LEN), dtype=np.int64)
    ],
)

# === STEP 5: Save .mlpackage
mlpackage_path = os.path.join(OUTPUT_DIR, MLPACKAGE_NAME)
mlmodel.save(mlpackage_path)
print(f"✅ Saved model to {mlpackage_path}")

# === STEP 6: Export vocab as JSON
print("📄 Exporting vocab to JSON format...")
vocab = tokenizer.get_vocab()
vocab = dict(sorted(vocab.items(), key=lambda item: item[1]))  # sort by ID

vocab_path = os.path.join(OUTPUT_DIR, VOCAB_JSON_FILENAME)
with open(vocab_path, "w", encoding="utf-8") as f:
    json.dump(vocab, f, indent=2, ensure_ascii=False)

print(f"✅ Saved vocab to {vocab_path}")
