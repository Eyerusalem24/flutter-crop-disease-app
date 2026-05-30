from flask import Blueprint, request, jsonify
from services.history_service import HistoryService

bp = Blueprint('history', __name__)
history_service = HistoryService()

@bp.route('/history', methods=['GET'])
def get_history():
    history = history_service.load_history()
    
    crop_filter = request.args.get('crop')
    if crop_filter:
        history = [h for h in history if h.get('crop') == crop_filter]
    
    return jsonify({
        'status': 'success',
        'count': len(history),
        'predictions': history
    })
