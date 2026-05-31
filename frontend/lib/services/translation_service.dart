import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService extends ChangeNotifier {
  static const String languageKey = 'selected_language';
  
  static Map<String, dynamic>? _enTranslations;
  static Map<String, dynamic>? _amTranslations;
  static String _currentLanguage = 'en';
  
  static TranslationService? _instance;
  static TranslationService get instance {
    _instance ??= TranslationService._();
    return _instance!;
  }
  
  TranslationService._();
  
  // ========== FALLBACK HARDCODED TRANSLATIONS ==========
  static final Map<String, dynamic> _fallbackEn = {
    "app_title": "Crop Disease Detection",
    "what_it_does": "What it does?",
    "quick_detection": "Quick Disease Detection",
    "quick_detection_desc": "Take a photo of any crop leaf",
    "ai_analysis": "AI Analysis",
    "ai_analysis_desc": "Advanced deep learning model",
    "treatment_advice": "Treatment Advice",
    "treatment_advice_desc": "Get instant treatment recommendations",
    "track_history": "Track History",
    "track_history_desc": "Save all your detection results",
    "get_started": "Get Started",
    "view_history": "View History",
    "analytics_dashboard": "Analytics Dashboard",
    "field_survey": "Field Survey",
    "model_performance": "Model Performance",
    "disease_encyclopedia": "Disease Encyclopedia",
    "no_camera": "No camera found on this device",
    "maize": "Maize",
    "tomato": "Tomato",
    "potato": "Potato",
    "wheat": "Wheat",
    "rice": "Rice",
    "all": "All",
    "search_disease": "Search disease...",
    "symptoms": "Symptoms",
    "cause": "Cause",
    "treatment": "Treatment",
    "prevention": "Prevention",
    "seasonal_info": "Seasonal Info",
    "not_available": "Information not available",
    "detection_history": "Detection History",
    "no_history": "No detection history yet",
    "empty_history_hint": "Take a photo and results will appear here",
    "go_to_camera": "Go to Camera",
    "confidence": "Confidence",
    "view_details": "View Details",
    "confirm_delete": "Confirm Delete",
    "delete_prediction_confirm": "Are you sure you want to delete this prediction?",
    "clear_all": "Clear All History",
    "clear_all_confirm": "Are you sure you want to clear all history? This cannot be undone.",
    "history_deleted": "History deleted",
    "all_history_cleared": "All history cleared",
    "cancel": "Cancel",
    "delete": "Delete",
    "no_data_export": "No data to export",
    "exported": "Exported",
    "export_failed": "Export failed",
  };

  static final Map<String, dynamic> _fallbackAm = {
    "app_title": "የሰብል በሽታ መለያ",
    "what_it_does": "ምን ያደርጋል?",
    "quick_detection": "ፈጣን የበሽታ መለየት",
    "quick_detection_desc": "የማንኛውም ሰብል ቅጠል ፎቶ ያንሱ",
    "ai_analysis": "አርቲፊሻል ኢንተሊጀንስ ትንተና",
    "ai_analysis_desc": "ዘመናዊ የዲፕ ላርኒንግ ሞዴል",
    "treatment_advice": "የህክምና ምክር",
    "treatment_advice_desc": "ፈጣን የህክምና ምክሮችን ያግኙ",
    "track_history": "ታሪክ ይከታተሉ",
    "track_history_desc": "ሁሉንም የምርመራ ውጤቶች ያስቀምጡ",
    "get_started": "ይጀምሩ",
    "view_history": "ታሪክ ይመልከቱ",
    "analytics_dashboard": "የትንታኔ ዳሽቦርድ",
    "field_survey": "የመስክ ቅኝት",
    "model_performance": "የሞዴል አፈጻጸም",
    "disease_encyclopedia": "የበሽታ መዝገበ ዕውቀት",
    "no_camera": "በዚህ መሳሪያ ላይ ምንም ካሜራ አልተገኘም",
    "maize": "በቆሎ",
    "tomato": "ቲማቲም",
    "potato": "ድንች",
    "wheat": "ስንዴ",
    "rice": "ሩዝ",
    "all": "ሁሉም",
    "search_disease": "በሽታ ፈልግ...",
    "symptoms": "ምልክቶች",
    "cause": "መንስኤ",
    "treatment": "ህክምና",
    "prevention": "መከላከያ",
    "seasonal_info": "የወቅት መረጃ",
    "not_available": "መረጃ አይገኝም",
    "detection_history": "የምርመራ ታሪክ",
    "no_history": "ምንም የምርመራ ታሪክ የለም",
    "empty_history_hint": "ምስል ይያዙ እና ውጤቶች እዚህ ይታያሉ",
    "go_to_camera": "ወደ መቅረጫ",
    "confidence": "እምነት",
    "view_details": "ዝርዝር",
    "confirm_delete": "መሰረዝ አረጋግጥ",
    "delete_prediction_confirm": "ይህን ትንበያ መሰረዝ እንደሚፈልጉ እርግጠኛ ነዎት?",
    "clear_all": "ሁሉንም ታሪክ አጥፋ",
    "clear_all_confirm": "ሁሉንም ታሪክ መሰረዝ እንደሚፈልጉ እርግጠኛ ነዎት? ይህ ሊቀለበስ አይችልም",
    "history_deleted": "ታሪክ ተሰርዟል",
    "all_history_cleared": "ሁሉም ታሪክ ተጠርጓል",
    "cancel": "ይቅር",
    "delete": "ሰርዝ",
    "no_data_export": "ለማውጣት ምንም ውሂብ የለም",
    "exported": "ወጥቷል",
    "export_failed": "ማውጣት አልተሳካም",
  };

  static Future<void> init() async {
    print('🔵 TranslationService.init() START');
    await loadTranslations('en');
    await loadTranslations('am');
    
    // Use fallback if assets failed
    if (_enTranslations == null) {
      _enTranslations = _fallbackEn;
      print('🔴 FALLBACK English assigned, size=${_enTranslations?.length}');
    }
    if (_amTranslations == null) {
      _amTranslations = _fallbackAm;
      print('🔴 FALLBACK Amharic assigned');
    }
    
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(languageKey) ?? 'en';
    print('✅ Translation service initialized. Current language: $_currentLanguage');
    instance.notifyListeners();
  }
  
  static Future<void> loadTranslations(String language) async {
    try {
      final path = 'assets/translations/$language.json';
      print('🔵 Loading $path ...');
      final jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> translations = json.decode(jsonString);
      if (language == 'en') {
        _enTranslations = translations;
        print('✅ Loaded English translations from assets. Keys: ${translations.keys.toList()}');
      } else if (language == 'am') {
        _amTranslations = translations;
        print('✅ Loaded Amharic translations from assets. Keys: ${translations.keys.toList()}');
      }
    } catch (e) {
      print('❌ Could not load $language from assets: $e');
    }
  }
  
  static String translate(String key, {String? language}) {
    final lang = language ?? _currentLanguage;
    final translations = lang == 'am' ? _amTranslations : _enTranslations;
    
    // Try loaded map first
    if (translations != null && translations.containsKey(key)) {
      final result = translations[key];
      if (key == 'detection_history') {
        print('translate("$key") => $result (from loaded map)');
      }
      return result;
    }
    
    // Fallback to hardcoded maps
    final fallback = lang == 'am' ? _fallbackAm : _fallbackEn;
    final fallbackResult = fallback[key] ?? key;
    if (key == 'detection_history') {
      print('translate("$key") => $fallbackResult (from fallback)');
    }
    return fallbackResult;
  }
  
  static String get currentLanguage => _currentLanguage;
  static bool get isAmharic => _currentLanguage == 'am';
  
  static Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageKey, language);
    print('✅ Language changed to: $language');
    instance.notifyListeners();
  }
  
  static Map<String, String> getSupportedLanguages() {
    return {'en': 'English', 'am': 'አማርኛ'};
  }
}