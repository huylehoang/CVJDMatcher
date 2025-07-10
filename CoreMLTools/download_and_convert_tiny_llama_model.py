import os
import shutil
from huggingface_hub import snapshot_download

# === CONFIGURATION ===
MODEL_ID = "TKDKid1000/TinyLlama-1.1B-Chat-v0.3-CoreML"  # public prebuilt CoreML model
TARGET_DIR = "../CVJDMatcher/CoreMLModels/TinyLlama"
PACKAGE_NAME = "tiny_llama.mlpackage"
OUTPUT_PATH = os.path.join(TARGET_DIR, PACKAGE_NAME)

# === STEP 1: Ensure target directory exists
os.makedirs(TARGET_DIR, exist_ok=True)

# === STEP 2: Download snapshot from Hugging Face
print(f"📥 Downloading snapshot of: {MODEL_ID}...")
snapshot_path = snapshot_download(
    repo_id=MODEL_ID,
    repo_type="model",
    local_dir_use_symlinks=False  # required to copy contents
)
print(f"✅ Downloaded to cache path: {snapshot_path}")

# === STEP 3: Search for .mlpackage inside downloaded folder
found_package = None
for root, dirs, files in os.walk(snapshot_path):
    for d in dirs:
        if d.endswith(".mlpackage"):
            found_package = os.path.join(root, d)
            break
    if found_package:
        break

if not found_package:
    raise FileNotFoundError("❌ Could not find a .mlpackage directory in the snapshot.")

# === STEP 4: Clean up old model if exists
if os.path.exists(OUTPUT_PATH):
    print(f"🧹 Removing old directory: {OUTPUT_PATH}")
    shutil.rmtree(OUTPUT_PATH)

# === STEP 5: Copy to project folder
print(f"📦 Copying .mlpackage to: {OUTPUT_PATH}")
shutil.copytree(found_package, OUTPUT_PATH)

# === DONE
print(f"🎉 Done! Llama 2 model is available at: {OUTPUT_PATH}")
