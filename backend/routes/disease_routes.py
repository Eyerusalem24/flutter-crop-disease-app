from flask import Blueprint, jsonify, request
import json
import os

bp = Blueprint('disease', __name__)

# Load disease mapping
def load_disease_mapping():
    path = os.path.join(os.path.dirname(__file__), '../disease_mapping.json')
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)['diseases']

DISEASES = load_disease_mapping()

# Create lookup dictionaries
NAME_TO_ID = {}
ID_TO_NAMES = {}
for d in DISEASES:
    NAME_TO_ID[d['name_en']] = d['id']
    NAME_TO_ID[d['name_am']] = d['id']
    ID_TO_NAMES[d['id']] = {'en': d['name_en'], 'am': d['name_am']}

@bp.route('/diseases', methods=['GET'])
def get_diseases():
    language = request.args.get('lang', 'en')
    diseases = [{'id': d['id'], 'name': d['name_en'] if language == 'en' else d['name_am']} for d in DISEASES]
    return jsonify({'status': 'success', 'diseases': diseases})

@bp.route('/diseases/crop/<crop>', methods=['GET'])
def get_diseases_by_crop(crop):
    language = request.args.get('lang', 'en')
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
        disease_id = NAME_TO_ID.get(disease)
        if disease_id:
            name = ID_TO_NAMES[disease_id][language]
            result.append({'id': disease_id, 'name': name})
    return jsonify({'status': 'success', 'diseases': result})

@bp.route('/disease/id/<int:disease_id>', methods=['GET'])
def get_disease_by_id(disease_id):
    language = request.args.get('lang', 'en')
    if disease_id in ID_TO_NAMES:
        name = ID_TO_NAMES[disease_id][language]
        return jsonify({'status': 'success', 'id': disease_id, 'name': name})
    return jsonify({'status': 'error', 'message': 'Disease not found'}), 404
