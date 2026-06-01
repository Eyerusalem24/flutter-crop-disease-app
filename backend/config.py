import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    UPLOAD_FOLDER = 'static/uploads'
    HISTORY_FILE = 'predictions_history.json'
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
    
    # Read API key from environment variable
    GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
    
    SUPPORTED_CROPS = ['maize', 'tomato', 'potato', 'wheat', 'rice']
    
    TARGET_SIZE = (224, 224)
    
    @staticmethod
    def init_directories():
        os.makedirs(Config.UPLOAD_FOLDER, exist_ok=True)
        os.makedirs('models', exist_ok=True)
