import json
import os
from datetime import datetime
from config import Config

class HistoryService:
    
    @staticmethod
    def load_history():
        if os.path.exists(Config.HISTORY_FILE):
            with open(Config.HISTORY_FILE, 'r') as f:
                return json.load(f)
        return []
    
    @staticmethod
    def save_to_history(crop, image_filename, disease, confidence, treatment):
        history = HistoryService.load_history()
        
        history.append({
            'id': len(history) + 1,
            'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            'crop': crop,
            'image': image_filename,
            'disease': disease,
            'confidence': round(confidence, 2),
            'treatment': treatment
        })
        
        with open(Config.HISTORY_FILE, 'w') as f:
            json.dump(history, f, indent=2)
        
        return history[-1]
