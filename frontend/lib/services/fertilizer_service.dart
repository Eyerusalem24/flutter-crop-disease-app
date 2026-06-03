import 'package:shared_preferences/shared_preferences.dart';
import 'translation_service.dart';

class FertilizerService {
  // Fertilizer recommendations database
  static final Map<String, Map<String, String>> _fertilizerDB = {
    // Maize Diseases
    'Gray Leaf Spot': {
      'fertilizer_en': 'NPK 20-10-10',
      'fertilizer_am': 'NPK 20-10-10',
      'application_en': 'Apply 150 kg/ha at planting, then 100 kg/ha after 30 days',
      'application_am': 'በሚተከልበት ጊዜ 150 ኪ.ግ/ሄክታር፣ ከ30 ቀናት በኋላ 100 ኪ.ግ/ሄክታር',
      'organic_en': 'Compost + Wood Ash (2:1 ratio)',
      'organic_am': 'ኮምፖስት + እንጨት አመድ (2:1 ጥምርታ)',
      'timing_en': 'Apply during early morning or evening',
      'timing_am': 'ማለዳ ወይም ማታ ላይ ይጠቀሙ',
      'frequency_en': 'Every 2 weeks during growing season',
      'frequency_am': 'በእድገት ወቅት በየ2 ሳምንቱ',
      'precautions_en': 'Avoid nitrogen-rich fertilizers as they can worsen the disease',
      'precautions_am': 'ናይትሮጅን የበዛባቸው ማዳበሪያዎችን ያስወግዱ',
    },
    'Common Rust': {
      'fertilizer_en': 'NPK 15-15-15',
      'fertilizer_am': 'NPK 15-15-15',
      'application_en': 'Apply 120 kg/ha at planting, side dress after 4 weeks',
      'application_am': 'በሚተከልበት ጊዜ 120 ኪ.ግ/ሄክታር፣ ከ4 ሳምንት በኋላ እንደገና',
      'organic_en': 'Neem cake + Vermicompost',
      'organic_am': 'ኒም ኬክ + ቬርሚኮምፖስት',
      'timing_en': 'Apply after weeding, before flowering',
      'timing_am': 'አረም ካጠፉ በኋላ፣ አበባ ከመውጣቱ በፊት',
      'frequency_en': 'Apply twice: at planting and at 30 days',
      'frequency_am': 'ሁለት ጊዜ: በሚተከልበት እና በ30ኛ ቀን',
      'precautions_en': 'Ensure balanced nutrition to strengthen plant immunity',
      'precautions_am': 'የተመጣጠነ አመጋገብ ለሰብል በሽታ መከላከያ',
    },
    'Northern Leaf Blight': {
      'fertilizer_en': 'NPK 10-20-20',
      'fertilizer_am': 'NPK 10-20-20',
      'application_en': 'Apply 180 kg/ha, focus on phosphorus and potassium',
      'application_am': '180 ኪ.ግ/ሄክታር፣ ፎስፈረስ እና ፖታስየም ላይ ትኩረት ያድርጉ',
      'organic_en': 'Bone meal + Potash + Compost',
      'organic_am': 'የአጥንት ዱቄት + ፖታሽ + ኮምፖስት',
      'timing_en': 'Apply before rainy season starts',
      'timing_am': 'የዝናብ ወቅት ከመጀመሩ በፊት',
      'frequency_en': 'Single deep application',
      'frequency_am': 'አንድ ጥልቅ አፕሊኬሽን',
      'precautions_en': 'Avoid foliar feeding as it spreads the disease',
      'precautions_am': 'በቅጠል ላይ ማዳበሪያ ማድረግን ያስወግዱ',
    },
    'Healthy': {
      'fertilizer_en': 'NPK 20-10-10 (maintenance)',
      'fertilizer_am': 'NPK 20-10-10 (ለጥገና)',
      'application_en': 'Apply 100 kg/ha every 45 days',
      'application_am': 'በየ45 ቀን 100 ኪ.ግ/ሄክታር',
      'organic_en': 'Compost tea + Mulch',
      'organic_am': 'ኮምፖስት ሻይ + ሙልች',
      'timing_en': 'Regular schedule every 6 weeks',
      'timing_am': 'በየ6 ሳምንቱ መደበኛ መርሃ ግብር',
      'frequency_en': '3-4 times per growing season',
      'frequency_am': 'በእድገት ወቅት 3-4 ጊዜ',
      'precautions_en': 'Maintain regular schedule for optimal health',
      'precautions_am': 'ለተሻለ ጤና መደበኛ መርሃ ግብር ይከተሉ',
    },
  };

  static Map<String, dynamic> getFertilizerRecommendation(String disease, String language) {
    final diseaseKey = _getMatchingDiseaseKey(disease);
    
    if (_fertilizerDB.containsKey(diseaseKey)) {
      final data = _fertilizerDB[diseaseKey]!;
      return {
        'fertilizer': language == 'am' ? data['fertilizer_am'] : data['fertilizer_en'],
        'application': language == 'am' ? data['application_am'] : data['application_en'],
        'organic_alternative': language == 'am' ? data['organic_am'] : data['organic_en'],
        'timing': language == 'am' ? data['timing_am'] : data['timing_en'],
        'frequency': language == 'am' ? data['frequency_am'] : data['frequency_en'],
        'precautions': language == 'am' ? data['precautions_am'] : data['precautions_en'],
      };
    }
    
    // Generic recommendation
    return {
      'fertilizer': language == 'am' ? 'የተመጣጠነ NPK ማዳበሪያ (15-15-15)' : 'Balanced NPK fertilizer (15-15-15)',
      'application': language == 'am' 
          ? 'በአካባቢዎ ግብርና ባለሙያ መሰረት ይጠቀሙ'
          : 'Apply according to local agricultural extension recommendations',
      'organic_alternative': language == 'am'
          ? 'በደንብ የበሰበሰ ኮምፖስት ወይም ፋርማርድ ማዳበሪያ'
          : 'Well-decomposed compost or farmyard manure',
      'timing': language == 'am'
          ? 'በቀዝቃዛ ሰዓታት (ማለዳ ወይም ማታ)'
          : 'Apply during cooler hours (early morning or late evening)',
      'frequency': language == 'am'
          ? 'በእድገት ወቅት በየ3-4 ሳምንቱ'
          : 'Every 3-4 weeks during growing season',
      'precautions': language == 'am'
          ? 'ከመጠቀምዎ በፊት የአፈር ምርመራ ይመከራል'
          : 'Soil test recommended before application',
    };
  }

  static String _getMatchingDiseaseKey(String disease) {
    // Try exact match
    if (_fertilizerDB.containsKey(disease)) return disease;
    
    // Try to match by keywords
    if (disease.contains('Gray') || disease.contains('Cercospora')) return 'Gray Leaf Spot';
    if (disease.contains('Rust')) return 'Common Rust';
    if (disease.contains('Northern') || disease.contains('Blight')) return 'Northern Leaf Blight';
    if (disease.contains('Healthy')) return 'Healthy';
    
    return disease;
  }
}
