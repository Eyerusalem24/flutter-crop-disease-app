import os

class Config:
    UPLOAD_FOLDER = 'static/uploads'
    HISTORY_FILE = 'predictions_history.json'
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
    GEMINI_API_KEY = "AQ.Ab8RN6JnGy9I9rqoHu1oX_dYa_EuawgzYClgmUQUKqZTOLc3hw"
    
    SUPPORTED_CROPS = ['maize', 'tomato', 'potato', 'wheat', 'rice']
    
    TARGET_SIZE = (224, 224)
    
    @staticmethod
    def init_directories():
        os.makedirs(Config.UPLOAD_FOLDER, exist_ok=True)
        os.makedirs('models', exist_ok=True)
