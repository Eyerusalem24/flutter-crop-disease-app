import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';
import '../services/history_service.dart';
import '../services/translation_service.dart';
import '../widgets/language_selector.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final HistoryService _historyService = HistoryService();
  
  bool _isLoading = true;
  Map<String, int> _diseaseFrequency = {};
  Map<String, int> _cropDistribution = {};
  Map<String, dynamic> _summaryStats = {};
  MapEntry<String, int>? _mostCommonDisease;
  Map<String, Map<String, int>> _trends = {};

  String _t(String key) => TranslationService.translate(key);
  bool get _isAmharic => TranslationService.currentLanguage == 'am';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    _diseaseFrequency = await _analyticsService.getDiseaseFrequency();
    _cropDistribution = await _analyticsService.getCropDistribution();
    _summaryStats = await _analyticsService.getSummaryStats();
    _mostCommonDisease = await _analyticsService.getMostCommonDisease();
    _trends = await _analyticsService.getDiseaseTrends();
    setState(() => _isLoading = false);
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
                      _t('analytics_dashboard'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Spacer(),
                    const LanguageSelector(),
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _summaryStats['total'] == 0
                          ? _buildEmptyState()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _buildSummaryCards(),
                                  const SizedBox(height: 24),
                                  _buildMostCommonCard(),
                                  const SizedBox(height: 24),
                                  _buildDiseaseChart(),
                                  const SizedBox(height: 24),
                                  _buildCropChart(),
                                  const SizedBox(height: 24),
                                  _buildTrendsChart(),
                                ],
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(_t('no_data_yet'), style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(_t('make_detections_to_see_analytics'), style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.camera_alt),
            label: Text(_t('go_to_camera')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(icon: Icons.analytics, title: _t('total'), value: '${_summaryStats['total']}', color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(icon: Icons.percent, title: _t('avg_confidence'), value: '${_summaryStats['avgConfidence']}%', color: Colors.green)),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMostCommonCard() {
    if (_mostCommonDisease == null) return const SizedBox.shrink();
    
    String diseaseName = _isAmharic 
        ? (_diseaseAm[_mostCommonDisease!.key] ?? _mostCommonDisease!.key) 
        : _mostCommonDisease!.key;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade700]), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.warning, color: Colors.orange, size: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('most_common_disease'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 4),
                Text(diseaseName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${_mostCommonDisease!.value} ${_t('detections')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseChart() {
    if (_diseaseFrequency.isEmpty) return const SizedBox.shrink();
    final entries = _diseaseFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = entries.take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade100), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.pie_chart, color: Colors.green[700], size: 20), const SizedBox(width: 8), Text(_t('disease_distribution'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]))]),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: top5.asMap().entries.map((entry) {
                String diseaseName = _isAmharic ? (_diseaseAm[entry.value.key] ?? entry.value.key) : entry.value.key;
                return PieChartSectionData(
                  value: entry.value.value.toDouble(),
                  title: diseaseName.length > 15 ? '${diseaseName.substring(0, 12)}...' : diseaseName,
                  radius: 80,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  color: [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple][entry.key % 5],
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            )),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: top5.asMap().entries.map((entry) {
            final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple];
            String diseaseName = _isAmharic ? (_diseaseAm[entry.value.key] ?? entry.value.key) : entry.value.key;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[entry.key % colors.length], shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(diseaseName.length > 20 ? '${diseaseName.substring(0, 17)}...' : diseaseName, style: const TextStyle(fontSize: 10)),
            ]);
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildCropChart() {
    if (_cropDistribution.isEmpty) return const SizedBox.shrink();
    final entries = _cropDistribution.entries.toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade100), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.agriculture, color: Colors.green[700], size: 20), const SizedBox(width: 8), Text(_t('crop_distribution'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]))]),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: entries.map((e) => e.value.toDouble()).reduce((a, b) => a > b ? a : b) + 1,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < entries.length) {
                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_t(entries[index].key), style: const TextStyle(fontSize: 10)));
                  }
                  return const Text('');
                }, reservedSize: 30)),
              ),
              barGroups: entries.asMap().entries.map((entry) => BarChartGroupData(x: entry.key, barRods: [BarChartRodData(toY: entry.value.value.toDouble(), color: Colors.green, width: 30, borderRadius: BorderRadius.circular(4))])).toList(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChart() {
    if (_trends.isEmpty) return const SizedBox.shrink();
    final days = _trends.keys.toList()..sort();
    final diseases = _getTopDiseases(3);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade100), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.trending_up, color: Colors.green[700], size: 20), const SizedBox(width: 8), Text(_t('disease_trends'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]))]),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < days.length) return Text(days[index], style: const TextStyle(fontSize: 10));
                  return const Text('');
                }, reservedSize: 30)),
              ),
              lineBarsData: diseases.map((disease) => LineChartBarData(
                spots: days.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), (_trends[entry.value]?[disease] ?? 0).toDouble())).toList(),
                isCurved: true,
                color: _getDiseaseColor(disease),
                barWidth: 3,
                dotData: const FlDotData(show: true),
              )).toList(),
            )),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 12, children: diseases.map((disease) {
            String displayName = _isAmharic ? (_diseaseAm[disease] ?? disease) : disease;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 12, height: 12, color: _getDiseaseColor(disease)),
              const SizedBox(width: 4),
              Text(displayName.length > 15 ? '${displayName.substring(0, 12)}...' : displayName, style: const TextStyle(fontSize: 10)),
            ]);
          }).toList()),
        ],
      ),
    );
  }

  List<String> _getTopDiseases(int count) {
    final entries = _diseaseFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(count).map((e) => e.key).toList();
  }

  Color _getDiseaseColor(String disease) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple];
    return colors[disease.hashCode.abs() % colors.length];
  }

  final Map<String, String> _diseaseAm = {
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
}
