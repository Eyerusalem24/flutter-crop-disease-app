import os
import random
import numpy as np

# Make TensorFlow optional
try:
    import tensorflow as tf
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False
    print("⚠️ TensorFlow not available - running in demo mode")

from models.disease_data import DISEASE_CLASSES

class ModelLoader:
    def __init__(self):
        self.models = {}
    
    def load_model_for_crop(self, crop):
        if not TF_AVAILABLE:
            return None
        
        if crop not in self.models:
            model_path = f'models/{crop}_model.h5'
            if os.path.exists(model_path):
                try:
                    self.models[crop] = tf.keras.models.load_model(model_path)
                    print(f"✅ Loaded model for {crop}")
                except Exception as e:
                    print(f"❌ Error loading {crop} model: {e}")
                    self.models[crop] = None
            else:
                self.models[crop] = None
        return self.models[crop]
    
    def predict(self, crop, model, processed_img):
        if model is not None and TF_AVAILABLE:
            predictions = model.predict(processed_img)
            class_idx = np.argmax(predictions[0])
            confidence = float(np.max(predictions[0]) * 100)
            disease_name = DISEASE_CLASSES[crop][class_idx]
        else:
            # Demo mode
            disease_name = random.choice(DISEASE_CLASSES[crop])
            confidence = round(random.uniform(75.0, 98.0), 2)
        
        return disease_name, confidence
