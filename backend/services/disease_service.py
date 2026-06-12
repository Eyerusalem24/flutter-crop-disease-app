import json
import os

class DiseaseService:
    def __init__(self):
        self.diseases = self._load_mapping()
        self._create_maps()
    
    def _load_mapping(self):
        path = os.path.join(os.path.dirname(__file__), '../disease_mapping.json')
        # Force UTF-8 encoding to handle Amharic characters
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)['diseases']
    
    def _create_maps(self):
        self.name_to_id = {}
        self.id_to_names = {}
        for d in self.diseases:
            self.name_to_id[d['name_en']] = d['id']
            self.name_to_id[d['name_am']] = d['id']
            self.id_to_names[d['id']] = {'en': d['name_en'], 'am': d['name_am']}
    
    def get_disease_id(self, name):
        return self.name_to_id.get(name)
    
    def get_disease_name(self, disease_id, language='en'):
        if disease_id in self.id_to_names:
            return self.id_to_names[disease_id][language]
        return 'Unknown'
    
    def get_all_diseases(self, language='en'):
        return [{'id': d['id'], 'name': d['name_en'] if language == 'en' else d['name_am']} 
                for d in self.diseases]
    
    def get_diseases_by_crop(self, crop, language='en'):
        crop_diseases = {
            'maize': ['Gray Leaf Spot', 'Common Rust', 'Northern Leaf Blight', 'Healthy'],
            'tomato': ['Late Blight', 'Early Blight', 'Leaf Mold', 'Septoria Leaf Spot', 'Healthy'],
            'potato': ['Late Blight', 'Early Blight', 'Healthy'],
            'wheat': ['Stripe Rust', 'Leaf Rust', 'Stem Rust', 'Healthy'],
            'rice': ['Blast', 'Blight', 'Sheath Rot', 'Healthy']
        }
        diseases = crop_diseases.get(crop, [])
        result = []
        for disease in diseases:
            disease_id = self.name_to_id.get(disease)
            if disease_id:
                result.append({'id': disease_id, 'name': self.get_disease_name(disease_id, language)})
        return result
