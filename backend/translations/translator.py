from .en import TRANSLATIONS as EN_TRANSLATIONS
from .am import TRANSLATIONS as AM_TRANSLATIONS

class Translator:
    """Multilingual translation service for the application"""
    
    SUPPORTED_LANGUAGES = {
        'en': 'English',
        'am': 'Amharic (አማርኛ)'
    }
    
    def __init__(self, default_language='en'):
        self.default_language = default_language
        self.translations = {
            'en': EN_TRANSLATIONS,
            'am': AM_TRANSLATIONS
        }
    
    def translate(self, key, language=None):
        """Translate a key to the specified language"""
        lang = language or self.default_language
        
        if lang not in self.translations:
            lang = 'en'
        
        return self.translations[lang].get(key, key)
    
    def get_text(self, key, lang='en', **kwargs):
        """Get translated text with optional formatting"""
        text = self.translate(key, lang)
        
        # Format with provided arguments
        if kwargs:
            try:
                text = text.format(**kwargs)
            except (KeyError, IndexError):
                pass
        
        return text
    
    def get_supported_languages(self):
        """Return list of supported languages"""
        return self.SUPPORTED_LANGUAGES
    
    def add_translation(self, lang, key, value):
        """Add a new translation dynamically"""
        if lang not in self.translations:
            self.translations[lang] = {}
        self.translations[lang][key] = value

# Create a global translator instance
translator = Translator()

# Helper function for easy access
def t(key, lang='en', **kwargs):
    """Shortcut function for translation"""
    return translator.get_text(key, lang, **kwargs)
