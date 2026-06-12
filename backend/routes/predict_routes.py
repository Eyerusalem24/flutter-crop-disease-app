from flask import Blueprint, request, jsonify
from datetime import datetime
import os
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import json
import cv2
import numpy as np
from config import Config
from services.gemini_service import GeminiService
from services.image_service import ImageService

bp = Blueprint('predict', __name__)
gemini_service = GeminiService()
image_service = ImageService()

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Loading model on {device}...")

class_names = ['Blight', 'Common_Rust', 'Gray_Leaf_Spot', 'Healthy', 'Not_Maize_Leaf']
print(f"Classes: {class_names}")

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

# GradCAM variables
gradients = None
activations = None

def forward_hook(module, input, output):
    global activations
    activations = output

def backward_hook(module, grad_input, grad_output):
    global gradients
    gradients = grad_output[0]

target_layer = model.features[-1]
target_layer.register_forward_hook(forward_hook)
target_layer.register_full_backward_hook(backward_hook)

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

TREATMENTS = {
    'Blight': 'Remove infected leaves. Apply copper-based fungicide.',
    'Common_Rust': 'Use resistant varieties. Apply fungicide containing mancozeb.',
    'Gray_Leaf_Spot': 'Apply fungicides containing azoxystrobin. Improve air circulation.',
    'Healthy': 'Your plant appears healthy. Continue regular care.',
    'Not_Maize_Leaf': 'This does not appear to be a maize leaf.'
}

def generate_heatmap(image_path, target_class, original_image_path):
    global gradients, activations
    
    img = Image.open(original_image_path).convert('RGB')
    input_tensor = transform(img).unsqueeze(0).to(device)
    
    output = model(input_tensor)
    model.zero_grad()
    output[0, target_class].backward()
    
    # FIX: Use .detach().numpy() instead of .numpy()
    grad = gradients.detach().cpu().numpy()[0]
    act = activations.detach().cpu().numpy()[0]
    
    weights = np.mean(grad, axis=(1, 2))
    cam = np.zeros(act.shape[1:], dtype=np.float32)
    for i, w in enumerate(weights):
        cam += w * act[i]
    
    cam = np.maximum(cam, 0)
    if cam.max() > 0:
        cam = cam / cam.max()
    
    original_img = cv2.imread(original_image_path)
    h, w = original_img.shape[:2]
    cam = cv2.resize(cam, (w, h))
    heatmap = cv2.applyColorMap(np.uint8(255 * cam), cv2.COLORMAP_JET)
    overlay = cv2.addWeighted(original_img, 0.6, heatmap, 0.4, 0)
    cv2.imwrite(image_path, overlay)
    print(f"✅ Heatmap saved: {image_path}")
    return True

@bp.route('/predict', methods=['POST'])
def predict():
    try:
        crop = request.form.get('crop', 'maize').lower()
        language = request.form.get('language', 'en')
        
        if 'image' not in request.files:
            return jsonify({'error': 'No image uploaded'}), 400
        
        file = request.files['image']
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{crop}_{timestamp}_{file.filename}"
        filepath = os.path.join(Config.UPLOAD_FOLDER, filename)
        file.save(filepath)
        
        enhanced_path = image_service.enhance_image(filepath)
        
        image = Image.open(enhanced_path).convert('RGB')
        input_tensor = transform(image).unsqueeze(0).to(device)
        
        with torch.no_grad():
            output = model(input_tensor)
            probabilities = torch.nn.functional.softmax(output, dim=1)
            confidence, predicted = torch.max(probabilities, 1)
        
        disease_name = class_names[predicted.item()]
        confidence_score = float(confidence.item()) * 100
        treatment = TREATMENTS.get(disease_name, "Consult local agricultural expert")
        
        # Generate heatmap
        heatmap_url = None
        try:
            heatmap_filename = f"{crop}_{timestamp}_heatmap.jpg"
            heatmap_path = os.path.join(Config.UPLOAD_FOLDER, heatmap_filename)
            generate_heatmap(heatmap_path, predicted.item(), enhanced_path)
            heatmap_url = f"/static/uploads/{heatmap_filename}"
            print(f"✅ Heatmap URL: {heatmap_url}")
        except Exception as e:
            print(f"⚠️ Heatmap failed: {e}")
            import traceback
            traceback.print_exc()
        
        gemini_advice = ""
        try:
            gemini_advice = gemini_service.get_advice(crop, disease_name, confidence_score, treatment, language)
        except Exception as e:
            print(f"⚠️ Gemini failed: {e}")
        
        return jsonify({
            'status': 'success',
            'crop': crop,
            'prediction': {
                'disease': disease_name,
                'confidence': confidence_score,
                'treatment': treatment,
                'gemini_advice': gemini_advice,
                'heatmap_url': heatmap_url
            },
            'image_url': f"/static/uploads/{os.path.basename(enhanced_path)}"
        })
        
    except Exception as e:
        print(f"❌ Prediction error: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500
