from flask import Blueprint, request, jsonify
from translations.translator import translator

bp = Blueprint('language', __name__)

@bp.route('/languages', methods=['GET'])
def get_languages():
    """Get supported languages"""
    return jsonify({
        'status': 'success',
        'languages': translator.get_supported_languages(),
        'default': 'en'
    })

@bp.route('/translate', methods=['GET'])
def translate():
    """Translate a key"""
    key = request.args.get('key', '')
    lang = request.args.get('lang', 'en')
    
    if not key:
        return jsonify({'error': 'No translation key provided'}), 400
    
    translated_text = translator.translate(key, lang)
    
    return jsonify({
        'status': 'success',
        'key': key,
        'language': lang,
        'translation': translated_text
    })
