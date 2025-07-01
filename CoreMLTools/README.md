# CVJDMatcher – Core ML Embedding & Reasoning Models Setup (`CoreMLModels`)

---

## 📁 Folder Structure

```
CVJDMatcher/
├── CoreMLTools/
│   ├── download_and_convert_embedding_model.py   # ✅ Convert MiniLM to CoreML
│   ├── export_minilm_vocab.py                    # ✅ Export MiniLM vocab only
│   ├── download_and_convert_reasoning_model.py   # ✅ Convert distilgpt2 to CoreML
│   ├── export_gpt2_vocab.py                      # ✅ Export distilgpt2 vocab only
│   ├── export_gpt2_merges.py                     # ✅ Export distilgpt2 merges only
│   └── setup_env.sh                              # ✅ One-click environment setup
├── CVJDMatcher/                                  # Xcode iOS project
│   ├── CoreMLModels/
│   │   ├── MiniLMEmbedding.mlpackage     # 🧠 Embedding model (384-dim vector)
│   │   ├── MiniLMVocab.json              # 📄 Vocab used by MiniLM tokenizer
│   │   ├── ReasoningModel.mlpackage      # 💬 Reasoning LLM (distilgpt2)
│   │   ├── GPT2Vocab.json                # 📄 Vocab used by GPT-2 tokenizer
│   │   └── GPT2Merges.json               # 🔗 BPE merges for GPT-2 tokenizer
```

---

## 🚀 One-Time Setup (macOS)

> 📦 This will download, convert, and export both embedding + reasoning models.

### ✅ Requirements

- macOS (Apple Silicon preferred)
- Homebrew installed
- Python 3.11+  
  👉 Install via: `brew install python@3.11`

---

### ✅ Run Setup Script

```bash
cd CoreMLTools
chmod +x setup_env.sh
./setup_env.sh
```

This will:

- Setup virtual environment (`venv`)
- Install dependencies: `torch`, `transformers`, `coremltools`
- Run:
  - `download_and_convert_embedding_model.py`
  - `export_minilm_vocab.py`
  - `download_and_convert_reasoning_model.py`
  - `export_gpt2_vocab.py`
  - `export_gpt2_merges.py`
- Output will be placed inside `CVJDMatcher/CoreMLModels/`
- Skip any model that already exists
- Auto-clean the venv when done

---

## 🧠 Model Summary

| Type      | Model Source                             | Output                          | Usage                                 |
|-----------|-------------------------------------------|----------------------------------|----------------------------------------|
| Embedding | `sentence-transformers/all-MiniLM-L6-v2` | 384-dim vector `[CLS]`          | Vector similarity scoring between JD & CV |
| Reasoning | `distilgpt2`                             | Text explanation (Match, Score) | LLM-generated explanation for best CV  |

> Cosine similarity is used to rank CVs for a given JD based on MiniLM embeddings.  
> The top CV is passed to the reasoning model for natural-language explanation.

---

## 🛠 How to Use in Swift

- Load with `MLModel(contentsOf:)`
- Prepare input using `MLDictionaryFeatureProvider`
- You can embed text, or generate reasoning explanation entirely offline.
- `.mlpackage` is already compiled and can be embedded in Xcode project.

---

## 🔁 Re-run After Changes

To re-convert after model update or cleanup:

```bash
cd CoreMLTools
./setup_env.sh
```

- It will skip models that already exist.
- To force re-convert: delete `*.mlpackage` or vocab JSON files manually before rerunning.

---
