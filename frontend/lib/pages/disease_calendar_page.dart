import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/translation_service.dart';
import '../widgets/language_selector.dart';

class DiseaseCalendarPage extends StatefulWidget {
  const DiseaseCalendarPage({super.key});

  @override
  State<DiseaseCalendarPage> createState() => _DiseaseCalendarPageState();
}

class _DiseaseCalendarPageState extends State<DiseaseCalendarPage> {
  String _selectedCrop = 'maize';
  int _selectedMonth = DateTime.now().month;
  
  final List<String> _crops = ['maize', 'tomato', 'potato', 'wheat', 'rice'];
  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  // Disease risk data for each crop by month (0-100)
  final Map<String, Map<String, List<int>>> _diseaseRiskData = {
    'maize': {
      'Gray Leaf Spot': [10, 15, 20, 40, 70, 85, 90, 85, 60, 30, 15, 10],
      'Common Rust': [5, 10, 15, 30, 65, 80, 85, 80, 55, 25, 10, 5],
      'Northern Leaf Blight': [5, 10, 20, 45, 75, 90, 85, 70, 50, 25, 10, 5],
    },
    'tomato': {
      'Late Blight': [5, 10, 20, 40, 75, 90, 85, 80, 60, 30, 15, 5],
      'Early Blight': [10, 15, 25, 50, 80, 85, 80, 75, 55, 35, 20, 10],
      'Leaf Mold': [5, 10, 15, 35, 70, 85, 90, 85, 65, 30, 15, 5],
    },
    'potato': {
      'Late Blight': [10, 15, 25, 50, 80, 95, 90, 85, 65, 35, 20, 10],
      'Early Blight': [5, 10, 20, 45, 75, 85, 80, 75, 55, 25, 15, 5],
    },
    'wheat': {
      'Stripe Rust': [5, 10, 20, 40, 70, 85, 90, 85, 60, 30, 15, 5],
      'Leaf Rust': [10, 15, 25, 45, 75, 80, 85, 80, 55, 25, 15, 10],
      'Stem Rust': [5, 5, 15, 35, 65, 80, 85, 80, 60, 30, 15, 5],
    },
    'rice': {
      'Blast': [10, 15, 25, 55, 85, 90, 85, 80, 60, 35, 20, 10],
      'Blight': [5, 10, 20, 50, 80, 85, 80, 75, 55, 25, 15, 5],
      'Sheath Rot': [5, 10, 20, 40, 70, 85, 90, 85, 65, 30, 15, 5],
    },
  };

  Map<String, String> _getPreventiveReminders(String crop, String disease, int month) {
    final isAmharic = TranslationService.isAmharic;
    final risk = _getRiskLevel(_diseaseRiskData[crop]?[disease]?[month - 1] ?? 0);
    
    Map<String, String> reminders = {};
    
    if (risk == 'High' || risk == 'Very High') {
      reminders = isAmharic
          ? {
              'action': 'የመከላከያ ፈንገስ መድሀኒት ይጠቀሙ',
              'frequency': 'በየ7-10 ቀናት',
              'monitor': 'በየቀኑ ቅጠሎችን ይፈትሹ',
            }
          : {
              'action': 'Apply preventive fungicide',
              'frequency': 'Every 7-10 days',
              'monitor': 'Check leaves daily for symptoms',
            };
    } else if (risk == 'Medium') {
      reminders = isAmharic
          ? {
              'action': 'የሰብል ሁኔታን ይከታተሉ',
              'frequency': 'በየ2 ሳምንቱ',
              'monitor': 'የበሽታ ምልክቶችን ይፈልጉ',
            }
          : {
              'action': 'Monitor crop condition',
              'frequency': 'Every 2 weeks',
              'monitor': 'Look for early disease signs',
            };
    } else {
      reminders = isAmharic
          ? {
              'action': 'መደበኛ እንክብካቤ በቂ ነው',
              'frequency': 'በየወሩ',
              'monitor': 'መደበኛ ቁጥጥር በቂ ነው',
            }
          : {
              'action': 'Normal care is sufficient',
              'frequency': 'Monthly',
              'monitor': 'Routine monitoring only',
            };
    }
    return reminders;
  }

  String _getRiskLevel(int risk) {
    if (risk >= 80) return 'Very High';
    if (risk >= 60) return 'High';
    if (risk >= 40) return 'Medium';
    if (risk >= 20) return 'Low';
    return 'Very Low';
  }

  Color _getRiskColor(int risk) {
    if (risk >= 80) return Colors.red;
    if (risk >= 60) return Colors.orange;
    if (risk >= 40) return Colors.yellow.shade700;
    if (risk >= 20) return Colors.lightGreen;
    return Colors.green;
  }

  String _getRiskLevelAmharic(int risk) {
    if (risk >= 80) return 'ከፍተኛ';
    if (risk >= 60) return 'ከፍተኛ';
    if (risk >= 40) return 'መካከለኛ';
    if (risk >= 20) return 'ዝቅተኛ';
    return 'በጣም ዝቅተኛ';
  }

  @override
  Widget build(BuildContext context) {
    final isAmharic = TranslationService.isAmharic;
    final currentRiskData = _diseaseRiskData[_selectedCrop] ?? {};
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isAmharic ? 'የበሽታ ቀን መቁጠሪያ' : 'Disease Calendar'),
        backgroundColor: Colors.green,
        actions: const [LanguageSelector()],
      ),
      body: Column(
        children: [
          // Crop selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  isAmharic ? 'ሰብል ይምረጡ' : 'Select Crop',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _crops.map((crop) {
                    final isSelected = _selectedCrop == crop;
                    return FilterChip(
                      label: Text(
                        isAmharic
                            ? _getCropNameAmharic(crop)
                            : crop.toUpperCase(),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCrop = crop;
                        });
                      },
                      backgroundColor: Colors.grey.shade200,
                      selectedColor: Colors.green,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Month selector
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _months.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedMonth == index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMonth = index + 1;
                    });
                  },
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isAmharic ? _getMonthNameAmharic(index) : _months[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Risk chart for selected month
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAmharic ? 'የበሽታ ስጋት ትንበያ' : 'Disease Risk Forecast',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 100,
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text('${value.toInt()}%');
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final diseases = currentRiskData.keys.toList();
                                        if (value.toInt() < diseases.length) {
                                          return Text(
                                            isAmharic
                                                ? _getDiseaseNameAmharic(diseases[value.toInt()])
                                                : diseases[value.toInt()],
                                            style: const TextStyle(fontSize: 10),
                                          );
                                        }
                                        return const Text('');
                                      },
                                      reservedSize: 60,
                                    ),
                                  ),
                                ),
                                barGroups: currentRiskData.keys.toList().asMap().entries.map((entry) {
                                  final risk = currentRiskData[entry.value]?[_selectedMonth - 1] ?? 0;
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: risk.toDouble(),
                                        color: _getRiskColor(risk),
                                        width: 30,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Disease details for selected month
                  ...currentRiskData.entries.map((entry) {
                    final disease = entry.key;
                    final risk = entry.value[_selectedMonth - 1];
                    final reminders = _getPreventiveReminders(_selectedCrop, disease, _selectedMonth);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getRiskColor(risk),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          isAmharic ? _getDiseaseNameAmharic(disease) : disease,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isAmharic
                              ? 'ስጋት: ${_getRiskLevelAmharic(risk)} (${risk}%)'
                              : 'Risk: ${_getRiskLevel(risk)} ($risk%)',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                  Icons.warning,
                                  isAmharic ? 'የስጋት ደረጃ' : 'Risk Level',
                                  isAmharic ? _getRiskLevelAmharic(risk) : _getRiskLevel(risk),
                                  _getRiskColor(risk),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.agriculture,
                                  isAmharic ? 'የሚመከር እርምጃ' : 'Recommended Action',
                                  reminders['action'] ?? '',
                                  Colors.blue,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  isAmharic ? 'ድግግሞሽ' : 'Frequency',
                                  reminders['frequency'] ?? '',
                                  Colors.orange,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.visibility,
                                  isAmharic ? 'ክትትል' : 'Monitoring',
                                  reminders['monitor'] ?? '',
                                  Colors.purple,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.thermostat,
                                  isAmharic ? 'የሚመከር ወቅት' : 'Best Season',
                                  isAmharic ? 'ዝናባማ ወቅት' : 'Rainy season',
                                  Colors.teal,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 16),
                  
                  // Seasonal tips card
                  Card(
                    color: Colors.green.shade50,
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
                                isAmharic ? 'የወቅት ምክሮች' : 'Seasonal Tips',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isAmharic
                                ? _getSeasonalTipsAmharic(_selectedMonth, _selectedCrop)
                                : _getSeasonalTips(_selectedMonth, _selectedCrop),
                            style: const TextStyle(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  String _getCropNameAmharic(String crop) {
    switch (crop) {
      case 'maize': return 'በቆሎ';
      case 'tomato': return 'ቲማቲም';
      case 'potato': return 'ድንች';
      case 'wheat': return 'ስንዴ';
      case 'rice': return 'ሩዝ';
      default: return crop;
    }
  }

  String _getDiseaseNameAmharic(String disease) {
    final Map<String, String> amharicNames = {
      'Gray Leaf Spot': 'ግራጫ ቅጠል ነጠብጣብ',
      'Common Rust': 'ዝገት',
      'Northern Leaf Blight': 'ሰሜናዊ ቅጠል በሽታ',
      'Late Blight': 'ዘግይቶ የሚከሰት በሽታ',
      'Early Blight': 'ቀደምት በሽታ',
      'Leaf Mold': 'ቅጠል ሻጋታ',
      'Stripe Rust': 'መስመራዊ ዝገት',
      'Leaf Rust': 'ቅጠል ዝገት',
      'Stem Rust': 'ግንድ ዝገት',
      'Blast': 'ፍንዳታ',
      'Blight': 'በሽታ',
      'Sheath Rot': 'ሽፋን መበስበስ',
    };
    return amharicNames[disease] ?? disease;
  }

  String _getMonthNameAmharic(int index) {
    const months = ['ጥር', 'የካ', 'መጋ', 'ሚያ', 'ግን', 'ሰኔ', 'ሐም', 'ነሐ', 'መስ', 'ጥቅ', 'ህዳ', 'ታህ'];
    return months[index];
  }

  String _getSeasonalTips(int month, String crop) {
    if (month >= 6 && month <= 9) {
      return '🌧️ Rainy season: High risk for fungal diseases. Apply preventive fungicides every 7-10 days. Ensure proper drainage.';
    } else if (month >= 10 && month <= 11) {
      return '🍂 Post-rainy season: Monitor for late blight. Continue regular checks. Prepare for harvest.';
    } else if (month >= 12 || month <= 2) {
      return '❄️ Dry season: Disease pressure is lower. Focus on soil preparation and planning for next season.';
    } else {
      return '🌱 Growing season: Regular monitoring is crucial. Start preventive treatments early.';
    }
  }

  String _getSeasonalTipsAmharic(int month, String crop) {
    if (month >= 6 && month <= 9) {
      return '🌧️ የዝናብ ወቅት: ለፈንገስ በሽታዎች ከፍተኛ ስጋት አለ። በየ7-10 ቀናት መከላከያ ፈንገስ መድሀኒት ይጠቀሙ። ትክክለኛ የውሃ ፍሳሽ ያረጋግጡ።';
    } else if (month >= 10 && month <= 11) {
      return '🍂 ከዝናብ በኋላ: ለዘግይቶ በሽታ ክትትል ያድርጉ። መደበኛ ምርመራ ይቀጥሉ። ለመከር ዝግጁ ይሁኑ።';
    } else if (month >= 12 || month <= 2) {
      return '❄️ ደረቅ ወቅት: የበሽታ ስጋት ዝቅተኛ ነው። ለአፈር ዝግጅት እና ለቀጣይ ወቅት እቅድ ማውጣት ላይ ያተኩሩ።';
    } else {
      return '🌱 የእድገት ወቅት: መደበኛ ክትትል ወሳኝ ነው። ቀደም ብለው መከላከያ ህክምና ይጀምሩ።';
    }
  }
}
