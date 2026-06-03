import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../services/history_service.dart';
import '../widgets/language_selector.dart';

class CropRotationPlanner extends StatefulWidget {
  const CropRotationPlanner({super.key});

  @override
  State<CropRotationPlanner> createState() => _CropRotationPlannerState();
}

class _CropRotationPlannerState extends State<CropRotationPlanner> {
  final HistoryService _historyService = HistoryService();
  List<Map<String, dynamic>> _detectedDiseases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetectedDiseases();
  }

  Future<void> _loadDetectedDiseases() async {
    setState(() => _isLoading = true);
    try {
      final predictions = await _historyService.getPredictions(limit: 50);
      final diseaseCount = <String, int>{};

      for (var pred in predictions) {
        final disease = pred['disease']?.toString() ?? '';
        if (disease.isNotEmpty && disease != 'Healthy') {
          diseaseCount[disease] = (diseaseCount[disease] ?? 0) + 1;
        }
      }

      final sorted = diseaseCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _detectedDiseases = sorted.map((e) => ({
        'name': e.key,
        'count': e.value,
      })).toList();
    } catch (e) {
      print('Error loading diseases: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // Helper to get crop names in Amharic
  String _getCropName(String cropName, bool isAmharic) {
    if (!isAmharic) return cropName;
    
    switch (cropName.toLowerCase()) {
      case 'maize': return 'በቆሎ';
      case 'beans': return 'ባቄላ';
      case 'wheat': return 'ስንዴ';
      default: return cropName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAmharic = TranslationService.isAmharic;
    final currentYear = DateTime.now().year;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAmharic ? 'የሰብል መዞር እቅድ' : 'Crop Rotation Planner'),
        backgroundColor: Colors.green,
        actions: const [LanguageSelector()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rotation Plan Card
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Text(
                                isAmharic ? 'የሰብል መዞር እቅድ' : '3-Year Rotation Plan',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: screenWidth,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 20,
                                headingRowColor: WidgetStateProperty.all(Colors.green.shade100),
                                columns: [
                                  DataColumn(label: Text(isAmharic ? 'ዓመት' : 'Year', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isAmharic ? 'ሜዳ 1' : 'Field 1', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isAmharic ? 'ሜዳ 2' : 'Field 2', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isAmharic ? 'ሜዳ 3' : 'Field 3', style: const TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: [
                                  DataRow(cells: [
                                    DataCell(Text(currentYear.toString())),
                                    DataCell(Text(_getCropName('Maize', isAmharic))),
                                    DataCell(Text(_getCropName('Beans', isAmharic))),
                                    DataCell(Text(_getCropName('Wheat', isAmharic))),
                                  ]),
                                  DataRow(cells: [
                                    DataCell(Text((currentYear + 1).toString())),
                                    DataCell(Text(_getCropName('Beans', isAmharic))),
                                    DataCell(Text(_getCropName('Wheat', isAmharic))),
                                    DataCell(Text(_getCropName('Maize', isAmharic))),
                                  ]),
                                  DataRow(cells: [
                                    DataCell(Text((currentYear + 2).toString())),
                                    DataCell(Text(_getCropName('Wheat', isAmharic))),
                                    DataCell(Text(_getCropName('Maize', isAmharic))),
                                    DataCell(Text(_getCropName('Beans', isAmharic))),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Detected Diseases (if any)
                  if (_detectedDiseases.isNotEmpty)
                    Card(
                      color: Colors.red.shade50,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                Text(
                                  isAmharic ? 'ከቅርብ ጊዜ ጀምሮ የተገኙ በሽታዎች' : 'Recently Detected Diseases',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _detectedDiseases.map((d) => Chip(
                                avatar: Icon(Icons.science, size: 16, color: Colors.red[400]),
                                label: Text('${d['name']} (${d['count']})'),
                                backgroundColor: Colors.white,
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Tips Card
                  Card(
                    color: Colors.blue.shade50,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Text(
                                isAmharic ? 'ምክሮች' : 'Tips',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isAmharic
                                ? '• ሰብሎችን በየዓመቱ ማሽከርከር የአፈር ንጥረ ነገር ሚዛን ይጠብቃል\n'
                                  '• ጥራጥሬዎች (ባቄላ፣ ሙንጤ) ናይትሮጅን ወደ አፈር ይጨምራሉ\n'
                                  '• ማሽከርከር የበሽታ ዑደትን ይሰብራል\n'
                                  '• ከመትከልዎ በፊት የአፈር ምርመራ ያድርጉ'
                                : '• Rotating crops yearly maintains soil nutrient balance\n'
                                  '• Legumes (beans, peas) add nitrogen to soil\n'
                                  '• Rotation breaks disease cycles naturally\n'
                                  '• Test soil before planting for best results',
                            style: const TextStyle(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
