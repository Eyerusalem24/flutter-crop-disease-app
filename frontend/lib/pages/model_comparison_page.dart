import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/translation_service.dart';
import '../widgets/language_selector.dart';

class ModelComparisonPage extends StatefulWidget {
  const ModelComparisonPage({super.key});

  @override
  State<ModelComparisonPage> createState() => _ModelComparisonPageState();
}

class _ModelComparisonPageState extends State<ModelComparisonPage> {
  bool _showDetailedMetrics = false;

  @override
  Widget build(BuildContext context) {
    final isAmharic = TranslationService.isAmharic;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isAmharic ? 'የሞዴል ንጽጽር' : 'Model Comparison'),
        backgroundColor: Colors.green,
        actions: const [LanguageSelector()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildModelHeader('VGG16', Colors.blue, true),
                        const Icon(Icons.compare_arrows, size: 32, color: Colors.grey),
                        _buildModelHeader(isAmharic ? 'ሌላ ሞዴል' : 'Model B', Colors.orange, false),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAmharic 
                          ? 'ሁለት ሞዴሎችን በማነፃፀር ላይ'
                          : 'Comparing Two Deep Learning Models',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Key Metrics Cards
            Text(
              isAmharic ? 'ቁልፍ መለኪያዎች' : 'Key Metrics',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Accuracy', '88.3%', '92.1%', Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Precision', '85.2%', '89.5%', Colors.blue)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Recall', '84.8%', '88.3%', Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('F1 Score', '85.0%', '88.9%', Colors.purple)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Performance Chart
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAmharic ? 'የአፈጻጸም ንጽጽር' : 'Performance Comparison',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                  const metrics = ['Accuracy', 'Precision', 'Recall', 'F1'];
                                  if (value.toInt() < metrics.length) {
                                    return Text(metrics[value.toInt()]);
                                  }
                                  return const Text('');
                                },
                                reservedSize: 50,
                              ),
                            ),
                          ),
                          barGroups: [
                            _makeBarGroup(0, 88.3, 92.1),
                            _makeBarGroup(1, 85.2, 89.5),
                            _makeBarGroup(2, 84.8, 88.3),
                            _makeBarGroup(3, 85.0, 88.9),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegend('VGG16', Colors.blue),
                        const SizedBox(width: 24),
                        _buildLegend(isAmharic ? 'ሌላ ሞዴል' : 'Model B', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Detailed Comparison Table
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAmharic ? 'ዝርዝር ንጽጽር' : 'Detailed Comparison',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _showDetailedMetrics = !_showDetailedMetrics),
                          icon: Icon(_showDetailedMetrics ? Icons.visibility_off : Icons.visibility),
                          label: Text(isAmharic ? 'ሁሉንም አሳይ' : 'Show All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildComparisonRow(
                      isAmharic ? 'የሞዴል አይነት' : 'Model Type',
                      'VGG16',
                      isAmharic ? 'EfficientNet-B3' : 'EfficientNet-B3',
                    ),
                    _buildComparisonRow(
                      isAmharic ? 'የስልጠና ጊዜ' : 'Training Time',
                      '~8 hours',
                      '~6 hours',
                    ),
                    _buildComparisonRow(
                      isAmharic ? 'ማጠቃለያ ጊዜ' : 'Inference Time',
                      '~100ms',
                      '~80ms',
                    ),
                    _buildComparisonRow(
                      isAmharic ? 'የሞዴል መጠን' : 'Model Size',
                      '60 MB',
                      '45 MB',
                    ),
                    _buildComparisonRow(
                      isAmharic ? 'የበሽታ ክፍሎች' : 'Disease Classes',
                      '4',
                      '4',
                    ),
                    if (_showDetailedMetrics) ...[
                      _buildComparisonRow(
                        isAmharic ? 'መሰረታዊ ሞዴል' : 'Base Model',
                        'VGG16',
                        'EfficientNet-B3',
                      ),
                      _buildComparisonRow(
                        isAmharic ? 'ጥልቀት' : 'Depth',
                        '16 layers',
                        '32 layers',
                      ),
                      _buildComparisonRow(
                        isAmharic ? 'መለኪያዎች' : 'Parameters',
                        '138M',
                        '12M',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Strengths & Weaknesses
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAmharic ? 'ጥንካሬዎች እና ድክመቶች' : 'Strengths & Weaknesses',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildProsConsCard(
                            'VGG16',
                            [
                              '✅ Good for maize disease detection',
                              '✅ Proven architecture',
                              '✅ Works well with limited data',
                            ],
                            [
                              '❌ Larger model size',
                              '❌ Slower inference',
                              '❌ Older architecture',
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProsConsCard(
                            isAmharic ? 'EfficientNet' : 'EfficientNet-B3',
                            [
                              '✅ Higher accuracy',
                              '✅ Faster inference',
                              '✅ Smaller model size',
                              '✅ Modern architecture',
                            ],
                            [
                              '❌ Requires more training data',
                              '❌ Complex implementation',
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recommendation
            Card(
              elevation: 4,
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
                          isAmharic ? 'ምክር' : 'Recommendation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAmharic
                          ? 'VGG16 ሞዴል በአሁኑ ጊዜ በመተግበሪያው ውስጥ እየሰራ ነው። EfficientNet-B3 ሞዴል ከፍተኛ ትክክለኛነት እና ፈጣን አፈጻጸም ያለው በመሆኑ በቅርቡ ይጨመራል።'
                          : 'VGG16 is currently running in the app. EfficientNet-B3 will be added soon for better accuracy and faster performance.',
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildModelHeader(String name, Color color, bool isCurrent) {
    final isAmharic = TranslationService.isAmharic;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            isCurrent ? Icons.check_circle : Icons.science,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (isCurrent)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAmharic ? 'ንቁ' : 'Active',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String vgg16, String other, Color color) {
    final isAmharic = TranslationService.isAmharic;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 4),
                    Text(vgg16, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text('VGG16', style: const TextStyle(fontSize: 10)),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 4),
                    Text(other, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    Text(isAmharic ? 'ሌላ' : 'Model B', style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double vgg16, double other) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: vgg16, color: Colors.blue, width: 20),
        BarChartRodData(toY: other, color: Colors.orange, width: 20),
      ],
      barsSpace: 8,
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildComparisonRow(String metric, String vgg16, String other) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(metric, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 1, child: Text(vgg16, textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text(other, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildProsConsCard(String title, List<String> pros, List<String> cons) {
    final isAmharic = TranslationService.isAmharic;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              isAmharic ? 'ጥንካሬዎች' : 'Strengths',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 4),
            ...pros.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(p, style: const TextStyle(fontSize: 12)),
            )),
            const SizedBox(height: 12),
            Text(
              isAmharic ? 'ድክመቶች' : 'Weaknesses',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 4),
            ...cons.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(c, style: const TextStyle(fontSize: 12)),
            )),
          ],
        ),
      ),
    );
  }
}
