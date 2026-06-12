"""
Convert PyTorch EfficientNet model to TensorFlow Lite
"""
import torch
import torch.nn as nn
from torchvision import models
import json
import os

print("="*50)
print("Converting PyTorch to TFLite")
print("="*50)

# 1. Load model
print("\n1. Loading model...")
with open("models/class_names.json", "r") as f:
    class_names = json.load(f)
print(f"   Classes: {class_names}")

# Create model
model = models.efficientnet_b0(weights=None)
in_features = model.classifier[1].in_features
model.classifier[1] = nn.Linear(in_features, len(class_names))

# Load weights
model.load_state_dict(torch.load("models/efficientnet_maize_best.pth", map_location='cpu'))
model.eval()
print("   ✅ Model loaded")

# 2. Export to ONNX
print("\n2. Exporting to ONNX...")
dummy_input = torch.randn(1, 3, 224, 224)
onnx_path = "models/model.onnx"
torch.onnx.export(
    model, dummy_input, onnx_path,
    input_names=['input'], output_names=['output'],
    opset_version=11
)
print(f"   ✅ ONNX saved to {onnx_path}")

# 3. Install onnx2tf if not already
print("\n3. Installing onnx2tf...")
os.system("pip install onnx2tf -q")

# 4. Convert to TensorFlow
print("\n4. Converting to TensorFlow...")
os.system(f"onnx2tf -i {onnx_path} -o models/tf_model")

# 5. Convert to TFLite
print("\n5. Converting to TFLite...")
import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model("models/tf_model")
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

tflite_path = "models/model.tflite"
with open(tflite_path, "wb") as f:
    f.write(tflite_model)

size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
print(f"   ✅ TFLite model saved: {tflite_path}")
print(f"   📦 Size: {size_mb:.2f} MB")

# 6. Save class names for mobile
print("\n6. Saving class names...")
with open("models/classes.txt", "w") as f:
    for name in class_names:
        f.write(f"{name}\n")
print("   ✅ classes.txt saved")

print("\n" + "="*50)
print("✅ CONVERSION COMPLETE!")
print("="*50)
print(f"\n📱 Model files ready:")
print(f"   - {tflite_path}")
print(f"   - models/classes.txt")
print("\nCopy these to your Flutter app's assets/models/ folder")
