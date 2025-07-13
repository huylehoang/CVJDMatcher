import os, json
from transformers import AutoTokenizer, AutoModel
import torch, numpy as np
import coremltools as ct

MODEL_ID = "sentence-transformers/stsb-roberta-large"
OUTPUT_DIR = "../CVJDMatcher/CoreMLModels/StsbRoberta"
MLPACKAGE = "stsb_roberta_large.mlpackage"
VOCAB_JSON = "stsb_roberta_large_vocab.json"
MAX_LEN = 128

os.makedirs(OUTPUT_DIR, exist_ok=True)

print(f"➡️ Loading tokenizer & model for {MODEL_ID}...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
hf_model = AutoModel.from_pretrained(MODEL_ID)
hf_model.eval().requires_grad_(False)

# Export vocab.json
print("📄 Saving vocab.json...")
with open(os.path.join(OUTPUT_DIR, VOCAB_JSON), "w", encoding="utf-8") as f:
    json.dump(tokenizer.get_vocab(), f, indent=2)

# Wrap to output CLS or mean pooling
class PoolModel(torch.nn.Module):
    def __init__(self, model):
        super().__init__()
        self.model = model
    def forward(self, input_ids, attention_mask):
        outputs = self.model(input_ids=input_ids, attention_mask=attention_mask)[0]
        mask = attention_mask.unsqueeze(-1).expand(outputs.size()).float()
        summed = torch.sum(outputs * mask, dim=1)
        counts = torch.clamp(mask.sum(dim=1), min=1e-9)
        return summed / counts

wrapped = PoolModel(hf_model)
dummy = torch.randint(0, tokenizer.vocab_size, (1, MAX_LEN), dtype=torch.long)
mask = torch.ones((1, MAX_LEN), dtype=torch.long)

print("📦 Tracing model...")
traced = torch.jit.trace(wrapped, (dummy, mask), strict=False)

print("🔁 Converting to Core ML (.mlpackage)...")
mlmodel = ct.convert(
    traced,
    convert_to="mlprogram",
    source="pytorch",
    inputs=[
        ct.TensorType(name="input_ids", shape=(1, MAX_LEN), dtype=np.int64),
        ct.TensorType(name="attention_mask", shape=(1, MAX_LEN), dtype=np.int64),
    ],
)
mlmodel.save(os.path.join(OUTPUT_DIR, MLPACKAGE))
print("✅ Model saved:", os.path.join(OUTPUT_DIR, MLPACKAGE))
