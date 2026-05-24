from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import numpy as np
import os
import json
from datetime import datetime
import tensorflow as tf
import cv2
import random

app = Flask(__name__)
CORS(app)

# ============================================
# CONFIGURATION
# ============================================

UPLOAD_FOLDER = 'static/uploads'
HISTORY_FILE = 'predictions_history.json'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs('models', exist_ok=True)

# ============================================
# IMAGE ENHANCEMENT FUNCTION
# ============================================

def enhance_image(image_path):
    """
    Enhance low-quality image using OpenCV
    - Denoising
    - CLAHE contrast enhancement
    - Upscaling
    - Gentle sharpening
    """

    try:
        # Read image
        img = cv2.imread(image_path)

        if img is None:
            print(f"❌ Could not read image: {image_path}")
            return image_path

        print(f"📷 Original shape: {img.shape}")

        # ============================================
        # STEP 1: DENOISE
        # ============================================

        denoised = cv2.fastNlMeansDenoisingColored(
            img,
            None,
            10,
            10,
            7,
            21
        )

        # ============================================
        # STEP 2: CLAHE CONTRAST ENHANCEMENT
        # ============================================

        lab = cv2.cvtColor(denoised, cv2.COLOR_BGR2LAB)

        l, a, b = cv2.split(lab)

        clahe = cv2.createCLAHE(
            clipLimit=2.0,
            tileGridSize=(8, 8)
        )

        cl = clahe.apply(l)

        merged = cv2.merge((cl, a, b))

        contrast_enhanced = cv2.cvtColor(
            merged,
            cv2.COLOR_LAB2BGR
        )

        # ============================================
        # STEP 3: UPSCALE IMAGE
        # ============================================

        high_res = cv2.resize(
            contrast_enhanced,
            (512, 512),
            interpolation=cv2.INTER_CUBIC
        )

        # ============================================
        # STEP 4: GENTLE SHARPENING
        # ============================================

        gaussian = cv2.GaussianBlur(
            high_res,
            (0, 0),
            2.0
        )

        sharpened = cv2.addWeighted(
            high_res,
            2.5,
            gaussian,
            -0.5,
            0
        )

        # ============================================
        # SAVE ENHANCED IMAGE
        # ============================================

        base, ext = os.path.splitext(image_path)

        enhanced_path = f"{base}_enhanced{ext}"

        cv2.imwrite(enhanced_path, sharpened)

        print(f"✨ Enhanced image saved: {enhanced_path}")
        print(f"✨ Enhanced shape: {sharpened.shape}")

        return enhanced_path

    except Exception as e:
        print(f"⚠️ Enhancement failed: {e}")
        return image_path


# ============================================
# BLUR DETECTION FUNCTION
# ============================================

def is_blurry(image, threshold=25):

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    variance = cv2.Laplacian(
        gray,
        cv2.CV_64F
    ).var()

    return variance < threshold


# ============================================
# MULTI-CROP MODEL CONFIGURATION
# ============================================

SUPPORTED_CROPS = [
    'maize',
    'tomato',
    'potato',
    'wheat',
    'rice'
]

DISEASE_CLASSES = {
    'maize': [
        'Gray Leaf Spot',
        'Common Rust',
        'Northern Leaf Blight',
        'Healthy'
    ],

    'tomato': [
        'Late Blight',
        'Early Blight',
        'Leaf Mold',
        'Septoria Leaf Spot',
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

# ============================================
# TREATMENTS
# ============================================

TREATMENTS = {

    'maize': {
        'Gray Leaf Spot':
            'Apply fungicides. Remove infected leaves. Rotate crops for 2 years.',

        'Common Rust':
            'Use resistant varieties. Apply fungicides if severe.',

        'Northern Leaf Blight':
            'Apply fungicides. Practice crop rotation.',

        'Healthy':
            'Your maize crop is healthy! Continue good practices.'
    },

    'tomato': {
        'Late Blight':
            'Remove infected leaves. Apply copper-based fungicides.',

        'Early Blight':
            'Prune lower leaves. Apply fungicides containing chlorothalonil.',

        'Leaf Mold':
            'Improve air circulation. Reduce leaf wetness.',

        'Septoria Leaf Spot':
            'Remove infected leaves. Apply fungicides.',

        'Healthy':
            'Your tomato crop is healthy!'
    },

    'potato': {
        'Late Blight':
            'Apply fungicides immediately. Destroy infected plants.',

        'Early Blight':
            'Rotate crops. Apply protective fungicides.',

        'Healthy':
            'Your potato crop is healthy!'
    },

    'wheat': {
        'Stripe Rust':
            'Use resistant varieties. Apply fungicides at first sign.',

        'Leaf Rust':
            'Apply fungicides. Plant resistant varieties.',

        'Stem Rust':
            'Destroy volunteer wheat. Apply fungicides.',

        'Healthy':
            'Your wheat crop is healthy!'
    },

    'rice': {
        'Blast':
            'Use resistant varieties. Apply silicon fertilizers.',

        'Blight':
            'Drain fields. Avoid excess nitrogen.',

        'Sheath Rot':
            'Apply fungicides. Use clean seeds.',

        'Healthy':
            'Your rice crop is healthy!'
    }
}

# ============================================
# MODEL STORAGE
# ============================================

models = {}

# ============================================
# LOAD MODEL
# ============================================

def load_model_for_crop(crop):

    if crop not in models:

        model_path = f'models/{crop}_model.h5'

        if os.path.exists(model_path):

            models[crop] = tf.keras.models.load_model(model_path)

            print(f"✅ Loaded model for {crop}")

        else:

            print(f"⚠️ Model for {crop} not found. Using demo mode.")

            models[crop] = None

    return models[crop]

# ============================================
# IMAGE PREPROCESSING
# ============================================

def preprocess_image(image_path, target_size=(224, 224)):

    img = cv2.imread(image_path)

    if img is None:
        raise ValueError("Could not read image")

    # Convert BGR → RGB
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    # Resize
    img = cv2.resize(img, target_size)

    # Normalize
    img = img.astype('float32') / 255.0

    # Add batch dimension
    img = np.expand_dims(img, axis=0)

    return img

# ============================================
# FILE VALIDATION
# ============================================

def allowed_file(filename):

    return (
        '.' in filename and
        filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
    )

# ============================================
# HISTORY FUNCTIONS
# ============================================

def load_history():

    if os.path.exists(HISTORY_FILE):

        with open(HISTORY_FILE, 'r') as f:
            return json.load(f)

    return []

def save_to_history(crop, image_filename, disease, confidence, treatment):

    history = load_history()

    history.append({
        'id': len(history) + 1,
        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        'crop': crop,
        'image': image_filename,
        'disease': disease,
        'confidence': round(confidence, 2),
        'treatment': treatment
    })

    with open(HISTORY_FILE, 'w') as f:
        json.dump(history, f, indent=2)

# ============================================
# API ROUTES
# ============================================

@app.route('/', methods=['GET'])
def home():

    return jsonify({
        'status': 'success',
        'project': 'AI-Powered Multi-Crop Disease Detection',
        'supported_crops': SUPPORTED_CROPS,
        'message': 'Send POST request to /predict with crop type and image'
    })

@app.route('/health', methods=['GET'])
def health():

    loaded_models = {
        crop: model is not None
        for crop, model in models.items()
    }

    return jsonify({
        'status': 'healthy',
        'loaded_models': loaded_models,
        'supported_crops': SUPPORTED_CROPS,
        'timestamp': datetime.now().isoformat()
    })

# ============================================
# PREDICTION ROUTE
# ============================================

@app.route('/predict', methods=['POST'])
def predict():

    try:

        # ============================================
        # GET CROP TYPE
        # ============================================

        crop = request.form.get('crop', 'maize').lower()

        if crop not in SUPPORTED_CROPS:

            return jsonify({
                'error': f'Unsupported crop. Supported crops: {SUPPORTED_CROPS}'
            }), 400
        print(request.files)
        # ============================================
        # CHECK IMAGE
        # ============================================

        if 'image' not in request.files:

            return jsonify({
                'error': 'No image uploaded'
            }), 400

        file = request.files['image']

        if not allowed_file(file.filename):

            return jsonify({
                'error': 'Invalid file type. Use PNG, JPG, or JPEG'
            }), 400

        # ============================================
        # SAVE IMAGE
        # ============================================

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        filename = f"{crop}_{timestamp}_{file.filename}"

        filepath = os.path.join(
            UPLOAD_FOLDER,
            filename
        )

        file.save(filepath)
        print("Uploaded filename:", file.filename)
        print("Saved filepath:", filepath)

       
        # ============================================
        # ENHANCE IMAGE
        # ============================================

        enhanced_path = enhance_image(filepath)

        # ============================================
        # LOAD MODEL
        # ============================================

        model = load_model_for_crop(crop)

        # ============================================
        # REAL PREDICTION
        # ============================================

        if model is not None:

            processed_img = preprocess_image(enhanced_path)

            predictions = model.predict(processed_img)

            class_idx = np.argmax(predictions[0])

            confidence = float(np.max(predictions[0]) * 100)

            disease_name = DISEASE_CLASSES[crop][class_idx]

        else:

            # DEMO MODE

            disease_name = random.choice(
                DISEASE_CLASSES[crop]
            )

            confidence = round(
                random.uniform(75.0, 98.0),
                2
            )

        # ============================================
        # GET TREATMENT
        # ============================================

        treatment = TREATMENTS.get(
            crop,
            {}
        ).get(
            disease_name,
            "Consult local agricultural expert"
        )

        # ============================================
        # SAVE HISTORY
        # ============================================

        save_to_history(
            crop,
            filename,
            disease_name,
            confidence,
            treatment
        )

        # ============================================
        # RETURN RESULT
        # ============================================

        return jsonify({

            'status': 'success',

            'crop': crop,

            'prediction': {

                'disease': disease_name,

                'confidence': confidence,

                'treatment': treatment,

                'enhanced': True
            },

            'image_url': f"/static/uploads/{os.path.basename(enhanced_path)}"
        })

    except Exception as e:

        return jsonify({
            'error': str(e)
        }), 500
# ============================================
# HISTORY ROUTE
# ============================================

@app.route('/history', methods=['GET'])
def get_history():

    history = load_history()

    crop_filter = request.args.get('crop')

    if crop_filter:

        history = [
            h for h in history
            if h.get('crop') == crop_filter
        ]

    return jsonify({
        'status': 'success',
        'count': len(history),
        'predictions': history
    })

# ============================================
# CROPS ROUTE
# ============================================

@app.route('/crops', methods=['GET'])
def get_crops():

    return jsonify({
        'status': 'success',
        'crops': SUPPORTED_CROPS,
        'diseases': DISEASE_CLASSES
    })

# ============================================
# SERVE IMAGES
# ============================================

@app.route('/static/uploads/<filename>')
def get_uploaded_image(filename):

    return send_from_directory(
        UPLOAD_FOLDER,
        filename
    )

# ============================================
# RUN SERVER
# ============================================

if __name__ == '__main__':

    print("\n" + "=" * 60)

    print("🌾 AI-POWERED MULTI-CROP DISEASE DETECTION")

    print("=" * 60)

    print(f"✅ Supported crops: {', '.join(SUPPORTED_CROPS)}")

    print(f"📍 Server: http://localhost:5000")

    print("=" * 60)

    print("\n⚠️ DEMO MODE - Waiting for trained models")

    print("Place model files inside models/ folder:")

    for crop in SUPPORTED_CROPS:

        print(f" - models/{crop}_model.h5")

    print("=" * 60 + "\n")

    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )