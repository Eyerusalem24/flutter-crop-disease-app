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
    
    def load_model_for_crop(self, crop_name, model_type="efficientnet_b0"):
        """Load EfficientNet model for specific crop"""
        # Try different possible model names
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
        
        print(f"Looking for model: {model_path}")
        print(f"Exists: {model_path is not None}")
        
        if model_path and os.path.exists(model_path):
            # Load EfficientNet model (use B0, not B3)
            model = models.efficientnet_b0(weights=None)
            num_features = model.classifier[1].in_features
            
            # Get number of classes from saved model or use 5 for maize
            num_classes = self._get_num_classes_for_crop(crop_name)
            
            # Modify classifier
            model.classifier[1] = nn.Sequential(
                nn.Dropout(p=0.3),
                nn.Linear(num_features, 512),
                nn.ReLU(),
                nn.Dropout(p=0.3),
                nn.Linear(512, num_classes)
            )
            
            # Load weights with map_location to handle CPU
            state_dict = torch.load(model_path, map_location='cpu')
            model.load_state_dict(state_dict)
            model.eval()
            return model
        
        return None
    
    def _get_num_classes_for_crop(self, crop_name):
        """Return number of disease classes for each crop"""
        crop_classes = {
            'maize': 5,      # Blight, Common_Rust, Gray_Leaf_Spot, Healthy, Not_Maize_Leaf
            'tomato': 6,
            'potato': 3,
            'wheat': 4,
            'rice': 4,
        }
        return crop_classes.get(crop_name, 5)
    
    def get_supported_crops(self):
        return ['maize', 'tomato', 'potato', 'wheat', 'rice']
    
    def predict(self, crop_name, model, image_tensor):
        """
        Run inference on a single image
        """
        if model is None:
            raise ValueError(f"No model loaded for crop: {crop_name}")

        with torch.no_grad():
            outputs = model(image_tensor)

            # Get probabilities
            probabilities = torch.softmax(outputs, dim=1)

            confidence, predicted_idx = torch.max(probabilities, 1)

            confidence = confidence.item()
            predicted_idx = predicted_idx.item()

            # Get class names (must match training)
            class_names = self._get_class_names(crop_name)
            
            disease_name = class_names[predicted_idx]

            return disease_name, confidence * 100  # Return as percentage
    
    def _get_class_names(self, crop_name):
        """Must match training labels exactly - 5 classes for maize"""
        class_map = {
            'maize': [
                'Blight',
                'Common_Rust',
                'Gray_Leaf_Spot',
                'Healthy',
                'Not_Maize_Leaf'
            ],
            'tomato': [
                'Late Blight',
                'Early Blight',
                'Leaf Mold',
                'Septoria Leaf Spot',
                'Tomato Mosaic Virus',
                'Healthy'
            ],
            'potato': [
                'Late Blight',
                'Early Blight',
                'Healthy'
            ],
            'wheat': [
                'Stripe Rust',
                'Leaf Rust',
                'Stem Rust',
                'Healthy'
            ],
            'rice': [
                'Blast',
                'Blight',
                'Sheath Rot',
                'Healthy'
            ]
        }
        return class_map.get(crop_name, ['Unknown'])
