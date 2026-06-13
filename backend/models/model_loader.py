import os
import torch
import torch.nn as nn
from torchvision import models

class ModelLoader:
    def __init__(self, models_dir="models"):
        self.models_dir = models_dir
        self.loaded_models = {}
    
    def load_model_for_crop(self, crop_name, model_type="efficientnet_b0"):
        possible_paths = [
            os.path.join(self.models_dir, f"efficientnet_{crop_name}_best.pth"),
            os.path.join(self.models_dir, "efficientnet_maize_best.pth"),
            os.path.join(self.models_dir, "efficientnet_maize_clean.pth"),
            os.path.join(self.models_dir, "efficientnet_maize.pth"),
        ]
        
        model_path = None
        for path in possible_paths:
            if os.path.exists(path):
                model_path = path
                break
        
        print(f"Loading model from: {model_path}")
        
        if model_path and os.path.exists(model_path):
            # Load the state dict to get number of classes
            state_dict = torch.load(model_path, map_location='cpu')
            
            # Create model with SAME architecture as training
            model = models.efficientnet_b0(weights=None)
            num_features = model.classifier[1].in_features
            
            # Use SIMPLE classifier (matches training)
            num_classes = state_dict['classifier.1.weight'].shape[0]
            model.classifier[1] = nn.Linear(num_features, num_classes)
            
            # Load weights
            model.load_state_dict(state_dict)
            model.eval()
            print(f"✅ Model loaded with {num_classes} classes")
            return model
        
        return None
    
    def get_supported_crops(self):
        return ['maize', 'tomato', 'potato', 'wheat', 'rice']
    
    def predict(self, crop_name, model, image_tensor):
        if model is None:
            raise ValueError(f"No model loaded for crop: {crop_name}")

        with torch.no_grad():
            outputs = model(image_tensor)
            probabilities = torch.softmax(outputs, dim=1)
            confidence, predicted_idx = torch.max(probabilities, 1)
            
            class_names = self._get_class_names(crop_name)
            disease_name = class_names[predicted_idx.item()]
            
            return disease_name, confidence.item() * 100
    
    def _get_class_names(self, crop_name):
        class_map = {
            'maize': ['Blight', 'Common_Rust', 'Gray_Leaf_Spot', 'Healthy', 'Not_Maize_Leaf'],
            'tomato': ['Late Blight', 'Early Blight', 'Leaf Mold', 'Septoria Leaf Spot', 'Tomato Mosaic Virus', 'Healthy'],
            'potato': ['Late Blight', 'Early Blight', 'Healthy'],
            'wheat': ['Stripe Rust', 'Leaf Rust', 'Stem Rust', 'Healthy'],
            'rice': ['Blast', 'Blight', 'Sheath Rot', 'Healthy']
        }
        return class_map.get(crop_name, ['Unknown'])
