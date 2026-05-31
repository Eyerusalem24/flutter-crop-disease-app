from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from config import Config
from routes import predict_routes, history_routes, crop_routes, language_routes
from services.gemini_service import GeminiService

def create_app():
    app = Flask(__name__)
    CORS(app)
    
    # Initialize config
    app.config.from_object(Config)
    Config.init_directories()
    
    # Initialize services
    gemini_service = GeminiService()
    
    # Register blueprints
    app.register_blueprint(predict_routes.bp)
    app.register_blueprint(history_routes.bp)
    app.register_blueprint(crop_routes.bp)
    app.register_blueprint(language_routes.bp)
    
    # Root route
    @app.route('/', methods=['GET'])
    def home():
        return jsonify({
            'status': 'success',
            'project': 'AI-Powered Multi-Crop Disease Detection',
            'supported_crops': Config.SUPPORTED_CROPS,
            'message': 'Send POST request to /predict with crop type and image'
        })
    
    # Health check
    @app.route('/health', methods=['GET'])
    def health():
        from models.model_loader import ModelLoader
        model_loader = ModelLoader()
        loaded_models = {
            crop: model_loader.load_model_for_crop(crop) is not None
            for crop in Config.SUPPORTED_CROPS
        }
        
        return jsonify({
            'status': 'healthy',
            'loaded_models': loaded_models,
            'supported_crops': Config.SUPPORTED_CROPS,
            'timestamp': datetime.now().isoformat()
        })
    
    # Serve images
    @app.route('/static/uploads/<filename>')
    def get_uploaded_image(filename):
        return send_from_directory(Config.UPLOAD_FOLDER, filename)
    
    # Gemini test route
    @app.route('/gemini-test')
    def gemini_test():
        try:
            response = gemini_service.get_advice("tomato", "Late Blight", 95.0, "Apply copper-based fungicides")
            return jsonify({
                "status": "success",
                "response": response
            })
        except Exception as e:
            return jsonify({
                "status": "error",
                "message": str(e)
            }), 500
    
    return app

if __name__ == '__main__':
    from datetime import datetime
    
    app = create_app()
    
    print("\n" + "=" * 60)
    print("🌾 AI-POWERED MULTI-CROP DISEASE DETECTION")
    print("=" * 60)
    print(f"✅ Supported crops: {', '.join(Config.SUPPORTED_CROPS)}")
    print(f"📍 Server: http://localhost:5000")
    print("=" * 60)
    print("\n⚠️ DEMO MODE - Waiting for trained models")
    print("Place model files inside models/ folder:")
    for crop in Config.SUPPORTED_CROPS:
        print(f" - models/{crop}_model.h5")
    print("=" * 60 + "\n")
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )
