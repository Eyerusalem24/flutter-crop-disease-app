import 'package:flutter/material.dart';
import '../services/disease_encyclopedia_service.dart';
import '../services/translation_service.dart';

class DiseaseEncyclopediaPage extends StatefulWidget {
  const DiseaseEncyclopediaPage({super.key});

  @override
  State<DiseaseEncyclopediaPage> createState() => _DiseaseEncyclopediaPageState();
}

class _DiseaseEncyclopediaPageState extends State<DiseaseEncyclopediaPage> {
  final DiseaseEncyclopediaService _service = DiseaseEncyclopediaService();
  String _selectedCrop = 'all';
  String _searchQuery = '';
  List<String> _diseases = [];

  final List<String> _crops = ['all', 'maize', 'tomato', 'potato', 'wheat', 'rice'];

  // Helper method to get translated text
  String _t(String key) {
    return TranslationService.translate(key);
  }

  // Helper to get current language
  bool get _isAmharic => TranslationService.currentLanguage == 'am';

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  void _loadDiseases() {
    if (_selectedCrop == 'all') {
      _diseases = _service.getAllDiseases();
    } else {
      _diseases = _service.getDiseasesByCrop(_selectedCrop);
    }
    if (_searchQuery.isNotEmpty) {
      _diseases = _diseases.where((d) => d.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    setState(() {});
  }

  String _getTextFromInfo(Map<String, dynamic>? info, String key, String amKey) {
    if (info == null) return '';
    if (_isAmharic) {
      return info[amKey] ?? info[key] ?? '';
    }
    return info[key] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green[700]!, Colors.green[400]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      _t('disease_encyclopedia'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        final newLang = _isAmharic ? 'en' : 'am';
                        await TranslationService.setLanguage(newLang);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.language, color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _isAmharic ? 'EN' : 'አማ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          onChanged: (q) {
                            _searchQuery = q;
                            _loadDiseases();
                          },
                          decoration: InputDecoration(
                            hintText: _t('search_disease'),
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _crops.length,
                          itemBuilder: (context, index) {
                            final crop = _crops[index];
                            final isSelected = _selectedCrop == crop;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(crop == 'all' ? _t('all') : _t(crop).toUpperCase()),
                                selected: isSelected,
                                onSelected: (_) {
                                  _selectedCrop = crop;
                                  _loadDiseases();
                                },
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: Colors.green,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _diseases.length,
                          itemBuilder: (context, index) {
                            final name = _diseases[index];
                            final info = _service.getDiseaseInfo(name);
                            String displayName = _isAmharic ? _getDiseaseAmharicName(name) : name;
                            String symptomsText = '';
                            if (info != null) {
                              if (_isAmharic) {
                                symptomsText = info['symptoms_am'] ?? info['symptoms'] ?? '';
                              } else {
                                symptomsText = info['symptoms'] ?? '';
                              }
                            }
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(info?['icon'], color: Colors.green[700]),
                                ),
                                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(symptomsText, maxLines: 2, overflow: TextOverflow.ellipsis),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () => _showDetail(name, info),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDiseaseAmharicName(String englishName) {
    final Map<String, String> amharicNames = {
      'Gray Leaf Spot': 'ግራጫ ቅጠል ነጠብጣብ',
      'Common Rust': 'ዝገት',
      'Northern Leaf Blight': 'ሰሜናዊ ቅጠል በሽታ',
      'Healthy': 'ጤናማ',
      'Late Blight': 'ዘግይቶ የሚከሰት በሽታ',
      'Early Blight': 'ቀደምት በሽታ',
      'Leaf Mold': 'ቅጠል ሻጋታ',
      'Septoria Leaf Spot': 'ሴፕቶሪያ ቅጠል ነጠብጣብ',
      'Stripe Rust': 'መስመራዊ ዝገት',
      'Leaf Rust': 'ቅጠል ዝገት',
      'Stem Rust': 'ግንድ ዝገት',
      'Blast': 'ፍንዳታ',
      'Blight': 'በሽታ',
      'Sheath Rot': 'ሽፋን መበስበስ',
    };
    return amharicNames[englishName] ?? englishName;
  }

  void _showDetail(String name, Map<String, dynamic>? info) {
    String displayName = _isAmharic ? _getDiseaseAmharicName(name) : name;
    
    String symptoms = '';
    String cause = '';
    String treatment = '';
    String prevention = '';
    
    if (info != null) {
      if (_isAmharic) {
        symptoms = info['symptoms_am'] ?? info['symptoms'] ?? '';
        cause = info['cause_am'] ?? info['cause'] ?? '';
        treatment = info['treatment_am'] ?? info['treatment'] ?? '';
        prevention = info['prevention_am'] ?? info['prevention'] ?? '';
      } else {
        symptoms = info['symptoms'] ?? '';
        cause = info['cause'] ?? '';
        treatment = info['treatment'] ?? '';
        prevention = info['prevention'] ?? '';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(info?['icon'], color: Colors.green[700], size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        if (info?['scientificName'] != 'N/A' && info?['scientificName'] != null)
                          Text(info?['scientificName'], style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSection(Icons.description, _t('symptoms'), symptoms, Colors.red),
                const SizedBox(height: 16),
                _buildSection(Icons.science, _t('cause'), cause, Colors.orange),
                const SizedBox(height: 16),
                _buildSection(Icons.medical_services, _t('treatment'), treatment, Colors.green),
                const SizedBox(height: 16),
                _buildSection(Icons.shield, _t('prevention'), prevention, Colors.purple),
                const SizedBox(height: 16),
                if (info?['seasonalInfo'] != null)
                  _buildSection(Icons.calendar_today, _t('seasonal_info'), info?['seasonalInfo'], Colors.teal),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(IconData icon, String title, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        Text(content.isNotEmpty ? content : _t('not_available'), style: const TextStyle(height: 1.5)),
      ],
    );
  }
}
