# download_and_convert_embedding_model.py

import os
import torch
import numpy as np
import coremltools as ct
from transformers import AutoModel, AutoTokenizer

# === CONFIGURATION ===
MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"
OUTPUT_DIR = "../CVJDMatcher/CoreMLModels"
MLPACKAGE_NAME = "EmbeddingModel.mlpackage"
MAX_LEN = 128

# === STEP 1: Load tokenizer + model ===
print(f"🔍 Downloading model from HuggingFace: {MODEL_ID}")
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
hf_model = AutoModel.from_pretrained(MODEL_ID)
hf_model.eval()
hf_model.requires_grad_(False)

# === STEP 2: Wrap model for CLS token output
class CLSModel(torch.nn.Module):
    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, input_ids: torch.Tensor, attention_mask: torch.Tensor) -> torch.Tensor:
        outputs = self.model(input_ids=input_ids, attention_mask=attention_mask)
        return outputs.last_hidden_state[:, 0]  # CLS token

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

# === STEP 5: Save model
mlpackage_path = os.path.join(OUTPUT_DIR, MLPACKAGE_NAME)
mlmodel.save(mlpackage_path)
print(f"✅ Saved model to {mlpackage_path}")
