import os
import torch
import numpy as np
import coremltools as ct
from transformers import AutoTokenizer, AutoModel

# Step 1: Load tokenizer + model
MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"
print(f"🔍 Downloading model from HuggingFace: {MODEL_ID}")
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
hf_model = AutoModel.from_pretrained(MODEL_ID)
hf_model.eval()
hf_model.requires_grad_(False)

# Step 2: Wrap model inside nn.Module for tracing
class CLSModel(torch.nn.Module):
    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, input_ids: torch.Tensor, attention_mask: torch.Tensor) -> torch.Tensor:
        outputs = self.model(input_ids=input_ids, attention_mask=attention_mask)
        return outputs.last_hidden_state[:, 0]  # CLS token embedding

wrapped_model = CLSModel(hf_model)

# Step 3: Dummy input for tracing (use correct torch.int64 for tokenizer output)
max_len = 128
input_ids = torch.randint(low=0, high=tokenizer.vocab_size, size=(1, max_len), dtype=torch.long)
attention_mask = torch.ones((1, max_len), dtype=torch.long)

print("📦 Tracing model...")
traced = torch.jit.trace(wrapped_model, (input_ids, attention_mask), strict=False)

# Step 4: Convert to Core ML
print("🔁 Converting to Core ML (.mlpackage)...")
mlmodel = ct.convert(
    traced,
    convert_to="mlprogram",
    source="pytorch",
    inputs=[
        ct.TensorType(name="input_ids", shape=(1, max_len), dtype=np.int64),
        ct.TensorType(name="attention_mask", shape=(1, max_len), dtype=np.int64)
    ],
)

# Step 5: Save model
output_path = "../CVJDMatcher/CoreMLModels/EmbeddingModel.mlpackage"
mlmodel.save(output_path)
print(f"✅ Saved model to {output_path}")
