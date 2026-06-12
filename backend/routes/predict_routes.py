from flask import Blueprint, request, jsonify
from datetime import datetime
import os
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import json
from config import Config
from services.gemini_service import GeminiService
from services.image_service import ImageService

bp = Blueprint('predict', __name__)
gemini_service = GeminiService()
image_service = ImageService()

# Load model once at startup
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Loading model on {device}...")

# Load class names (5 classes for maize)
class_names = ['Blight', 'Common_Rust', 'Gray_Leaf_Spot', 'Healthy', 'Not_Maize_Leaf']
print(f"Classes: {class_names}")

# Load the model
model_path = 'models/efficientnet_maize_best.pth'
if not os.path.exists(model_path):
    model_path = 'models/efficientnet_maize_clean.pth'
if not os.path.exists(model_path):
    model_path = 'models/efficientnet_maize.pth'

print(f"Loading model from: {model_path}")

model = models.efficientnet_b0(weights=None)
in_features = model.classifier[1].in_features
model.classifier[1] = nn.Linear(in_features, len(class_names))
model.load_state_dict(torch.load(model_path, map_location='cpu'))
model = model.to(device)
model.eval()
print(f"✅ Model loaded with {len(class_names)} classes")

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# Treatment mapping for 5 classes
TREATMENTS = {
    'Blight': 'Remove infected leaves. Apply copper-based fungicide.',
    'Common_Rust': 'Use resistant varieties. Apply fungicide containing mancozeb.',
    'Gray_Leaf_Spot': 'Apply fungicides containing azoxystrobin. Improve air circulation.',
    'Healthy': 'Your plant appears healthy. Continue regular care.',
    'Not_Maize_Leaf': 'This does not appear to be a maize leaf. Please take a photo of a maize leaf.'
}

@bp.route('/predict', methods=['POST'])
def predict():
    try:
        crop = request.form.get('crop', 'maize').lower()
        language = request.form.get('language', 'en')
        
        if 'image' not in request.files:
            return jsonify({'error': 'No image uploaded'}), 400
        
        file = request.files['image']
        
        # Save original image
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{crop}_{timestamp}_{file.filename}"
        filepath = os.path.join(Config.UPLOAD_FOLDER, filename)
        file.save(filepath)
        
        # Enhance image
        enhanced_path = image_service.enhance_image(filepath)
        
        # Load and preprocess image
        image = Image.open(enhanced_path).convert('RGB')
        input_tensor = transform(image).unsqueeze(0).to(device)
        
        # Predict
        with torch.no_grad():
            output = model(input_tensor)
            probabilities = torch.nn.functional.softmax(output, dim=1)
            confidence, predicted = torch.max(probabilities, 1)
        
        disease_name = class_names[predicted.item()]
        confidence_score = float(confidence.item()) * 100
        
        # Get treatment
        treatment = TREATMENTS.get(disease_name, "Consult local agricultural expert")
        
        # Get Gemini advice
        gemini_advice = gemini_service.get_advice(crop, disease_name, confidence_score, treatment, language)
        
        return jsonify({
            'status': 'success',
            'crop': crop,
            'prediction': {
                'disease': disease_name,
                'confidence': confidence_score,
                'treatment': treatment,
                'gemini_advice': gemini_advice,
                'heatmap_url': ''
            },
            'image_url': f"/static/uploads/{os.path.basename(enhanced_path)}"
        })
        
    except Exception as e:
        print(f"❌ Prediction error: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500
