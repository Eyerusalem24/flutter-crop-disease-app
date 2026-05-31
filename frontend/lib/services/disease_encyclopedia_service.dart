import 'package:flutter/material.dart';

class DiseaseEncyclopediaService {
  final Map<String, Map<String, dynamic>> _diseases = {
    'Common Rust': {
      'scientificName': 'Puccinia sorghi',
      'symptoms': 'Small, circular to elongated cinnamon-brown pustules on leaves.',
      'cause': 'Fungus spread by wind-borne spores. Favors moderate temperatures (16-25°C).',
      'treatment': 'Apply fungicides containing azoxystrobin. Remove infected plant debris.',
      'prevention': 'Use resistant seed varieties. Practice crop rotation (2-3 years).',
      'seasonalInfo': 'Most common during warm, humid weather.',
      'icon': Icons.bug_report,
      'crops': ['maize'],
    },
    'Gray Leaf Spot': {
      'scientificName': 'Cercospora zeae-maydis',
      'symptoms': 'Small, rectangular gray to tan lesions with brown borders parallel to leaf veins.',
      'cause': 'Fungus surviving in crop residue. Favors warm, humid conditions.',
      'treatment': 'Apply strobilurin or triazole fungicides. Remove infected leaves.',
      'prevention': 'Rotate crops. Till under crop residue. Plant resistant hybrids.',
      'seasonalInfo': 'Most severe during grain fill period.',
      'icon': Icons.leak_add,
      'crops': ['maize'],
    },
    'Northern Leaf Blight': {
      'scientificName': 'Exserohilum turcicum',
      'symptoms': 'Large, canoe-shaped gray-green to tan lesions on leaves (2-15 cm long).',
      'cause': 'Fungus overwintering in crop residue. Favors cool (18-27°C), moist conditions.',
      'treatment': 'Apply fungicides at early disease development. Use resistant hybrids.',
      'prevention': 'Crop rotation. Residue management. Plant partially resistant varieties.',
      'seasonalInfo': 'Develops after tasseling under wet conditions.',
      'icon': Icons.eco,
      'crops': ['maize'],
    },
    'Late Blight': {
      'scientificName': 'Phytophthora infestans',
      'symptoms': 'Large, irregular water-soaked lesions turning dark brown. White fuzzy growth underneath.',
      'cause': 'Water mold spreading rapidly in cool, wet weather.',
      'treatment': 'Apply copper-based fungicides immediately. Remove infected plants.',
      'prevention': 'Use disease-free seed. Avoid overhead watering. Ensure good air circulation.',
      'seasonalInfo': 'Most destructive during cool, wet weather.',
      'icon': Icons.water_damage,
      'crops': ['tomato', 'potato'],
    },
    'Early Blight': {
      'scientificName': 'Alternaria solani',
      'symptoms': 'Dark, concentric rings on lower leaves forming target-like spots.',
      'cause': 'Fungus surviving in soil and plant debris. Favors warm temperatures (24-29°C).',
      'treatment': 'Apply chlorothalonil or mancozeb fungicides. Remove infected lower leaves.',
      'prevention': 'Mulch around plants. Water at base. Stake plants for air flow.',
      'seasonalInfo': 'Appears on older leaves first. Worse in humid conditions.',
      'icon': Icons.circle,
      'crops': ['tomato', 'potato'],
    },
    'Stripe Rust': {
      'scientificName': 'Puccinia striiformis',
      'symptoms': 'Yellow to orange pustules arranged in stripes on leaves.',
      'cause': 'Fungus requiring cool temperatures (10-15°C) and moisture.',
      'treatment': 'Apply fungicides at first sign. Plant resistant varieties.',
      'prevention': 'Use resistant cultivars. Avoid early planting.',
      'seasonalInfo': 'Develops in cool, moist conditions. Can cause 40-100% yield loss.',
      'icon': Icons.linear_scale,
      'crops': ['wheat'],
    },
    'Blast': {
      'scientificName': 'Magnaporthe oryzae',
      'symptoms': 'Diamond-shaped lesions with gray centers and brown borders on leaves.',
      'cause': 'Fungus affecting all above-ground parts. Favors high humidity.',
      'treatment': 'Apply silicon fertilizers. Use resistant varieties. Avoid excess nitrogen.',
      'prevention': 'Use balanced fertilization. Drain fields periodically.',
      'seasonalInfo': 'Most destructive rice disease worldwide.',
      'icon': Icons.warning,
      'crops': ['rice'],
    },
    'Healthy': {
      'scientificName': 'N/A',
      'symptoms': 'No visible disease symptoms. Normal green color. Healthy growth pattern.',
      'cause': 'Plant is disease-free.',
      'treatment': 'Continue good agricultural practices. Monitor regularly.',
      'prevention': 'Maintain proper nutrition. Practice crop rotation.',
      'seasonalInfo': 'Maintain health through balanced fertilization.',
      'icon': Icons.check_circle,
      'crops': ['maize', 'tomato', 'potato', 'wheat', 'rice'],
    },
  };

  List<String> getAllDiseases() => _diseases.keys.toList();

  List<String> getDiseasesByCrop(String crop) {
    return _diseases.entries
        .where((e) => e.value['crops'].contains(crop))
        .map((e) => e.key)
        .toList();
  }

  Map<String, dynamic>? getDiseaseInfo(String name) => _diseases[name];
}
