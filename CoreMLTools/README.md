# CVJDMatcher – Core ML Embedding Model Setup Guide (CoreMLModels)

---

## 📁 Folder Structure

```
CVJDMatcher/
├── CoreMLModels/
│   ├── download_and_convert_embedding_model.py   # ✅ Python script to convert embedding model
│   ├── download_and_convert_reasoning_model.py   # ✅ Python script to convert reasoning model
│   └── setup_env.sh                              # ✅ One-time environment setup script
├── CVJDMatcher/                                  # Xcode iOS project
│   ├── CoreMLModels/
│   │   ├── MiniLMEmbedding.mlpackage             # ✅ Core ML embedding model
│   │   └── ReasoningModel.mlpackage              # ✅ Core ML reasoning model
│   └── ...
```

---

## 🚀 Quick Start (1-time setup)

This folder provides local scripts to download and convert **embedding + reasoning models** to `.mlpackage`.

### ✅ Prerequisites

- macOS with Homebrew installed
- Python 3.11+ (`brew install python@3.11`)

---

### ✅ Run Setup Script

```bash
cd CoreMLModels
chmod +x setup_env.sh
./setup_env.sh
```

This will:

- Create Python venv in `CoreMLModels/venv`
- Download & convert:
  - `sentence-transformers/all-MiniLM-L6-v2` → `MiniLMEmbedding.mlpackage`
  - `distilgpt2` → `ReasoningModel.mlpackage`
- Copy both `.mlpackage` files into the Xcode project folder
- Automatically skip models that already exist
- Clean up the virtual environment after run

---

## 🧠 Model Overview

| Type      | Model Name                                | Purpose                    | Output                          |
|-----------|-------------------------------------------|----------------------------|---------------------------------|
| Embedding | `MiniLMEmbedding.mlpackage`               | Embed JD/CV strings        | 384-dim vector (`[CLS]`)        |
| Reasoning | `ReasoningModel.mlpackage` (distilgpt2)   | Explain top match (LLM)    | Generated natural language      |

Use cosine similarity between vectors to rank CV relevance.

---

## 💡 Tips

- `.mlpackage` = folder-based Core ML model bundle
- Works fully offline with `CoreML.framework`
- Can be tested directly in Swift code via `MLModel(...)` + `MLDictionaryFeatureProvider(...)`
- No need to open or compile `.mlmodel` manually

---

## 🔁 Re-run Setup

To force re-download and reconversion:

```bash
cd CoreMLModels
./setup_env.sh
```

It will skip models that already exist unless deleted.

---
