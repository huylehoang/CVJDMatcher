# 🧠 CVJDMatcher

A native, offline, Core ML–powered iOS app that matches Job Descriptions (JDs) with CVs using AI embedding + local reasoning models.

---

## 📦 Overview

This project demonstrates an **on-device AI flow** using:

- ✅ **MiniLM Embedding model**: for sentence embedding (384-d vector)
- ✅ **DistilGPT2 model**: for local LLM-based explanation
- ✅ **Core ML**: for fully offline inference, no cloud or API needed
- ✅ **Swift + SwiftUI**: with Clean Architecture, async/await, dependency injection

---

## 🧭 Project Structure

```
CVJDMatcher/
├── CVJDMatcher/                                # 🧑‍💻 Xcode iOS app project
│   ├── CoreMLModels/                           # ✅ Contains .mlpackage files used at runtime
│   │   ├── MiniLMEmbedding.mlpackage
│   │   └── ReasoningModel.mlpackage
│   ├── Services/
│   |   ├── EmbeddingService.swift              # Uses MiniLM for sentence embedding
│   |   └── ReasoningService.swift              # Uses DistilGPT2 to explain top match
│   ├── Content/
│   |   ├── ContentViewModel.swift
│   |   └── ContentView.swift
│
├── CoreMLTools/                                 # 🧪 Python conversion scripts
│   ├── download_and_convert_embedding_model.py
│   ├── download_and_convert_reasoning_model.py
│   ├── setup_env.sh
│   └── README.md                                # 🔗 Setup instructions here
│
├── developer-guide.md                           # 📘 Guide for Core ML beginners
└── README.md                                    # 📘 (You're here)
```

---

## 🚀 Getting Started

> ⚠️ Before running the Xcode app, you must download and convert the `.mlpackage` models.

### ✅ Step 1: Setup Core ML Models

> Follow the instructions in [`CoreMLTools/README.md`](./CoreMLTools/README.md) to:

- Install Python dependencies
- Download models from Hugging Face
- Convert to Core ML `.mlpackage`
- Save directly into the `CVJDMatcher/CoreMLModels` folder

---

## 🧠 AI Flow

```
[ JD string ] ──embed──▶ [ vector A ]
       │
[ CV1, CV2, CV3 ] ──embed──▶ [ vector B1, B2, B3 ]

[ cosine(A, Bi) ] ──▶ sorted ──▶ explain(jd, cv)
                                       ⬇
                          "This CV matches because..."
```

---

## 🛠 Technologies Used

| Component     | Stack                                |
|---------------|---------------------------------------|
| ML Inference  | Core ML (`.mlpackage`)                |
| Embedding     | sentence-transformers/all-MiniLM-L6-v2 |
| Reasoning     | distilgpt2                            |
| Architecture  | Clean Architecture + SwiftUI + DI     |
| Language      | Swift + Python                        |

---

## 📱 SwiftUI Features

- `@MainActor` + `@ObservableObject` for clean state
- `Task.detached` to offload CoreML prediction from main thread
- Detailed error handling and async/await reasoning

---

## 📦 Notes

- `.mlpackage` is the Core ML bundle format
- Fully offline on-device inference
- Compatible with `CoreML`, `CreateMLComponents`, and `NLModel` usage in Swift
- You don’t need to drag `.mlpackage` into Xcode – just reference by path or bundle it
- But make sure `.mlpackage` is listed in **Compile Sources**, not **Copy Bundle Resources** to avoid duplication issues

---

## 🔁 Re-run Setup

To re-download or re-convert models:

```bash
cd CoreMLTools
./setup_env.sh
```

It will:

- Automatically skip models that already exist
- Clean up the virtual environment afterward

---

## ✅ Example Output

| CV                        | Score    | Explanation                              |
|--------------------------|----------|-------------------------------------------|
| Senior iOS with Swift    | 0.87     | "This CV is a strong match because..."    |
| React Engineer           | 0.42     | "Different stack, less relevant..."       |

---

## 🔗 See Also

- [`CoreMLTools/README.md`](./CoreMLTools/README.md) – Setup guide for model conversion
- [`developer-guide.md`](./developer-guide.md) – For iOS devs new to Core ML & model conversion
- [Core ML Tools Docs](https://apple.github.io/coremltools/)
- [HuggingFace Model – MiniLM](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2)
