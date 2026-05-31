from flask import Blueprint, request, jsonify
from datetime import datetime
import os
from config import Config
from models.model_loader import ModelLoader
from models.disease_data import TREATMENTS
from services.image_service import ImageService
from services.gemini_service import GeminiService
from services.history_service import HistoryService
from utils.validators import allowed_file

bp = Blueprint('predict', __name__)
model_loader = ModelLoader()
image_service = ImageService()
gemini_service = GeminiService()
history_service = HistoryService()

@bp.route('/predict', methods=['POST'])
def predict():
    try:
        # Get crop type
        crop = request.form.get('crop', 'maize').lower()
        
        if crop not in Config.SUPPORTED_CROPS:
            return jsonify({
                'error': f'Unsupported crop. Supported crops: {Config.SUPPORTED_CROPS}'
            }), 400
        
        # Check image
        if 'image' not in request.files:
            return jsonify({'error': 'No image uploaded'}), 400
        
        file = request.files['image']
        
        if not allowed_file(file.filename):
            return jsonify({
                'error': 'Invalid file type. Use PNG, JPG, or JPEG'
            }), 400
        
        # Save image
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{crop}_{timestamp}_{file.filename}"
        filepath = os.path.join(Config.UPLOAD_FOLDER, filename)
        file.save(filepath)
        
        # Enhance image
        enhanced_path = image_service.enhance_image(filepath)
        
        # Load model and predict
        model = model_loader.load_model_for_crop(crop)
        processed_img = image_service.preprocess_image(enhanced_path)
        disease_name, confidence = model_loader.predict(crop, model, processed_img)
        
        # Get treatment
        treatment = TREATMENTS.get(crop, {}).get(
            disease_name,
            "Consult local agricultural expert"
        )
        
        # Get Gemini advice
        gemini_advice = gemini_service.get_advice(crop, disease_name, confidence, treatment)
        
        # Save to history
        history_service.save_to_history(crop, filename, disease_name, confidence, treatment)
        
        # Return result
        return jsonify({
            'status': 'success',
            'crop': crop,
            'prediction': {
                'disease': disease_name,
                'confidence': confidence,
                'treatment': treatment,
                'gemini_advice': gemini_advice,
                'enhanced': True
            },
            'image_url': f"/static/uploads/{os.path.basename(enhanced_path)}"
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
