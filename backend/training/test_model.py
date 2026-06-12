import torch
import torch.nn as nn
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader
import json
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix
import numpy as np

print("="*50)
print("Testing Model on Hold-out Test Set")
print("="*50)

# Device
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Using device: {device}")

# Load class names
with open("models/class_names.json", "r") as f:
    class_names = json.load(f)
print(f"Classes: {class_names}")

# Data transform (same as training)
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# Load test dataset (you need to create a test folder first)
test_path = "models/Dataset_test"  # Change this to your test folder

# For now, use 20% of validation as test
# If you haven't split yet, use this:
from torch.utils.data import random_split

full_dataset = datasets.ImageFolder(root='models/Dataset', transform=transform)
total = len(full_dataset)
test_size = int(0.1 * total)  # 10% for testing
_, test_dataset = random_split(full_dataset, [total - test_size, test_size])

test_loader = DataLoader(test_dataset, batch_size=32, shuffle=False)

print(f"Test samples: {len(test_dataset)}")

# Load trained model
model = models.efficientnet_b0(weights=None)
in_features = model.classifier[1].in_features
model.classifier[1] = nn.Linear(in_features, len(class_names))
model.load_state_dict(torch.load("models/efficientnet_maize_best.pth", map_location='cpu'))
model = model.to(device)
model.eval()

# Run testing
all_preds = []
all_labels = []

with torch.no_grad():
    for images, labels in test_loader:
        images, labels = images.to(device), labels.to(device)
        outputs = model(images)
        _, predicted = torch.max(outputs, 1)
        all_preds.extend(predicted.cpu().numpy())
        all_labels.extend(labels.cpu().numpy())

# Calculate metrics
accuracy = accuracy_score(all_labels, all_preds)
precision = precision_score(all_labels, all_preds, average='weighted')
recall = recall_score(all_labels, all_preds, average='weighted')
f1 = f1_score(all_labels, all_preds, average='weighted')

print("\n" + "="*50)
print("TEST RESULTS (on 10% hold-out data)")
print("="*50)
print(f"✅ Test Accuracy:  {accuracy * 100:.2f}%")
print(f"✅ Test Precision: {precision * 100:.2f}%")
print(f"✅ Test Recall:    {recall * 100:.2f}%")
print(f"✅ Test F1-Score:  {f1 * 100:.2f}%")
print("="*50)

# Per-class accuracy
cm = confusion_matrix(all_labels, all_preds)
print("\nPer-class accuracy:")
for i, name in enumerate(class_names):
    class_acc = cm[i][i] / cm[i].sum() * 100
    print(f"  {name}: {class_acc:.2f}%")
