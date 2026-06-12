# -*- coding: utf-8 -*-
"""EfficientNet Training for Maize Disease Detection - 20 Epochs"""

import os
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader, random_split

# ============================================
# 1. SETUP & CONFIGURATION
# ============================================

# Set seed for reproducibility
seed = 42
torch.manual_seed(seed)

# Device configuration
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# Path to your dataset
base_path = "models/Dataset"

# Check if dataset exists
if not os.path.exists(base_path):
    print(f"Error: Dataset not found at {base_path}")
    exit(1)

# Training configuration
BATCH_SIZE = 32
EPOCHS = 20  # CHANGED TO 20
IMAGE_SIZE = 224
LEARNING_RATE = 0.001

# Early stopping configuration
PATIENCE = 5  # Stop if no improvement for 5 epochs
best_val_acc = 0
epochs_without_improvement = 0

# ============================================
# 2. DATA PREPROCESSING
# ============================================

print("\n" + "="*50)
print("Loading Dataset...")
print("="*50)

transform = transforms.Compose([
    transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

# Load dataset
dataset = datasets.ImageFolder(
    root=base_path,
    transform=transform
)

print(f"Total images: {len(dataset)}")
print(f"Classes found: {dataset.classes}")
print(f"Number of classes: {len(dataset.classes)}")

# Show class distribution
print("\nClass distribution:")
for class_name in dataset.classes:
    class_path = os.path.join(base_path, class_name)
    if os.path.isdir(class_path):
        num_images = len([f for f in os.listdir(class_path) if f.endswith(('.jpg', '.jpeg', '.png'))])
        print(f"  {class_name}: {num_images} images")

# Split into train (80%) and validation (20%)
train_size = int(0.8 * len(dataset))
val_size = len(dataset) - train_size

train_dataset, val_dataset = random_split(
    dataset,
    [train_size, val_size]
)

print(f"\nTrain samples: {len(train_dataset)}")
print(f"Validation samples: {len(val_dataset)}")

# Create DataLoaders
train_loader = DataLoader(
    train_dataset,
    batch_size=BATCH_SIZE,
    shuffle=True,
    num_workers=0
)

val_loader = DataLoader(
    val_dataset,
    batch_size=BATCH_SIZE,
    shuffle=False,
    num_workers=0
)

# ============================================
# 3. EFFICIENTNET MODEL
# ============================================

print("\n" + "="*50)
print("Creating EfficientNet Model...")
print("="*50)

def get_efficientnet_model(num_classes):
    """Load pretrained EfficientNet-B0 and modify classifier"""
    model = models.efficientnet_b0(weights=models.EfficientNet_B0_Weights.IMAGENET1K_V1)
    
    # Replace classifier for our number of classes
    in_features = model.classifier[1].in_features
    model.classifier[1] = nn.Linear(in_features, num_classes)
    
    return model.to(device)

num_classes = len(dataset.classes)
model = get_efficientnet_model(num_classes)
print(f"EfficientNet-B0 model created with {num_classes} output classes")
print(f"Total parameters: {sum(p.numel() for p in model.parameters()):,}")

# ============================================
# 4. LOSS FUNCTION & OPTIMIZER
# ============================================

criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=LEARNING_RATE)

# ============================================
# 5. TRAINING LOOP WITH PROGRESS TRACKING
# ============================================

print("\n" + "="*50)
print(f"Starting EfficientNet Training for {EPOCHS} Epochs")
print("="*50)

# Store metrics for plotting
train_losses = []
train_accs = []
val_accs = []

for epoch in range(EPOCHS):
    # Training phase
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    
    for images, labels in train_loader:
        images, labels = images.to(device), labels.to(device)
        
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        
        running_loss += loss.item()
        _, predicted = torch.max(outputs, 1)
        total += labels.size(0)
        correct += (predicted == labels).sum().item()
    
    train_loss = running_loss / len(train_loader)
    train_acc = 100. * correct / total
    train_losses.append(train_loss)
    train_accs.append(train_acc)
    
    # Validation phase
    model.eval()
    val_correct = 0
    val_total = 0
    
    with torch.no_grad():
        for images, labels in val_loader:
            images, labels = images.to(device), labels.to(device)
            outputs = model(images)
            _, predicted = torch.max(outputs, 1)
            val_total += labels.size(0)
            val_correct += (predicted == labels).sum().item()
    
    val_acc = 100. * val_correct / val_total
    val_accs.append(val_acc)
    
    # Calculate progress percentage
    progress = ((epoch + 1) / EPOCHS) * 100
    
    print(f"\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"Epoch [{epoch+1}/{EPOCHS}] - {progress:.0f}% Complete")
    print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"  📉 Train Loss: {train_loss:.4f}")
    print(f"  📈 Train Acc:  {train_acc:.2f}%")
    print(f"  🎯 Val Acc:    {val_acc:.2f}%")
    
    # Early stopping check
    if val_acc > best_val_acc:
        best_val_acc = val_acc
        epochs_without_improvement = 0
        # Save best model
        torch.save(model.state_dict(), "models/efficientnet_maize_best.pth")
        print(f"  💾 New best model saved! (Val Acc: {best_val_acc:.2f}%)")
    else:
        epochs_without_improvement += 1
        print(f"  ⏳ No improvement for {epochs_without_improvement} epochs")
        
        if epochs_without_improvement >= PATIENCE:
            print(f"\n  🛑 Early stopping triggered! No improvement for {PATIENCE} epochs.")
            print(f"  Best validation accuracy: {best_val_acc:.2f}%")
            break

print("\n" + "="*50)
print("Training Complete!")
print("="*50)

# ============================================
# 6. SAVE FINAL MODEL
# ============================================

# Save final model
torch.save(model.state_dict(), "models/efficientnet_maize.pth")
print(f"\n✅ Final model saved to: models/efficientnet_maize.pth")
print(f"✅ Best model saved to: models/efficientnet_maize_best.pth")

# Save class names
import json
class_names = dataset.classes
with open("models/class_names.json", "w") as f:
    json.dump(class_names, f)
print(f"✅ Class names saved to: models/class_names.json")
print(f"   Classes: {class_names}")

# Save training history
history = {
    "train_losses": train_losses,
    "train_accs": train_accs,
    "val_accs": val_accs,
    "best_val_acc": best_val_acc,
    "epochs_completed": len(train_losses)
}
with open("models/training_history.json", "w") as f:
    json.dump(history, f, indent=4)
print(f"✅ Training history saved")

# ============================================
# 7. FINAL SUMMARY
# ============================================

print("\n" + "="*50)
print("📊 TRAINING SUMMARY")
print("="*50)
print(f"  Total epochs run: {len(train_losses)}")
print(f"  Best validation accuracy: {best_val_acc:.2f}%")
print(f"  Final validation accuracy: {val_acc:.2f}%")
print(f"  Final training accuracy: {train_acc:.2f}%")
print(f"  Classes: {len(class_names)}")

if best_val_acc >= 90:
    print("\n  🎉 Excellent! Model is ready for deployment.")
elif best_val_acc >= 80:
    print("\n  👍 Good model. Could improve with more data.")
else:
    print("\n  ⚠️ Model needs improvement. Consider more data or epochs.")

print("\n" + "="*50)
print("✅ All done! Model is ready for use in your app.")
print("="*50)
