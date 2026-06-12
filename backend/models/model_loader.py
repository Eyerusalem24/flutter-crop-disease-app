"""
Model Loader for EfficientNet
Multi-Crop Disease Detection
"""
import os
import torch
import torch.nn as nn
from torchvision import models

class ModelLoader:
    def __init__(self, models_dir="models"):
        self.models_dir = models_dir
        self.loaded_models = {}
    
    def load_model_for_crop(self, crop_name, model_type="efficientnet_b3"):
        """Load EfficientNet model for specific crop"""
        model_path = os.path.join(self.models_dir, f"{crop_name}_{model_type}.pth")
        
        if os.path.exists(model_path):
            # Load EfficientNet model
            model = models.efficientnet_b3(weights=None)
            num_features = model.classifier[1].in_features
            num_classes = self._get_num_classes_for_crop(crop_name)
            
            model.classifier[1] = nn.Sequential(
                nn.Dropout(p=0.3),
                nn.Linear(num_features, 512),
                nn.ReLU(),
                nn.Dropout(p=0.3),
                nn.Linear(512, num_classes)
            )
            
            model.load_state_dict(torch.load(model_path, map_location='cpu'))
            model.eval()
            return model
        
        return None
    
    def _get_num_classes_for_crop(self, crop_name):
        """Return number of disease classes for each crop"""
        crop_classes = {
            'maize': 4,      # Gray Leaf Spot, Common Rust, Northern Leaf Blight, Healthy
            'tomato': 6,     # Late Blight, Early Blight, Leaf Mold, Septoria, etc.
            'potato': 3,     # Late Blight, Early Blight, Healthy
            'wheat': 4,      # Stripe Rust, Leaf Rust, Stem Rust, Healthy
            'rice': 4,       # Blast, Blight, Sheath Rot, Healthy
        }
        return crop_classes.get(crop_name, 4)
    
    def get_supported_crops(self):
        return ['maize', 'tomato', 'potato', 'wheat', 'rice']
