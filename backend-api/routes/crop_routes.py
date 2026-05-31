from flask import Blueprint, jsonify
from config import Config
from models.disease_data import DISEASE_CLASSES

bp = Blueprint('crops', __name__)

@bp.route('/crops', methods=['GET'])
def get_crops():
    return jsonify({
        'status': 'success',
        'crops': Config.SUPPORTED_CROPS,
        'diseases': DISEASE_CLASSES
    })
