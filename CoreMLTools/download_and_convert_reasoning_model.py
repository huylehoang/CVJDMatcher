import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
import coremltools as ct
import numpy as np

# === Config ===
MODEL_NAME = "distilgpt2"
MLPACKAGE_NAME = "../CVJDMatcher/CoreMLModels/ReasoningModel.mlpackage"

print(f"🔍 Downloading reasoning model: {MODEL_NAME}")
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
base_model = AutoModelForCausalLM.from_pretrained(MODEL_NAME)
base_model.eval()

# === Wrap model to return only logits ===
class LogitsOnlyModel(torch.nn.Module):
    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, input_ids):
        return self.model(input_ids=input_ids).logits

model = LogitsOnlyModel(base_model)

# === Dummy input for tracing ===
sample_text = "This CV matches because"
inputs = tokenizer(sample_text, return_tensors="pt")
input_ids = inputs["input_ids"]

print("📦 Tracing model...")
with torch.no_grad():
    traced = torch.jit.trace(model, input_ids, strict=False)

print("🔁 Converting to Core ML (.mlpackage)...")
mlmodel = ct.convert(
    traced,
    source="pytorch",
    inputs=[ct.TensorType(name="input_ids", shape=input_ids.shape, dtype=np.int32)],
    convert_to="mlprogram"
)

mlmodel.save(MLPACKAGE_NAME)
print(f"✅ Saved as {MLPACKAGE_NAME}")
