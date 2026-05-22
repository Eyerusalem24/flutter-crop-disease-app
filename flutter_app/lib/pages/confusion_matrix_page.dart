import 'package:flutter/material.dart';
import '../services/confusion_matrix_service.dart';

class ConfusionMatrixPage extends StatefulWidget {
  const ConfusionMatrixPage({super.key});

  @override
  State<ConfusionMatrixPage> createState() => _ConfusionMatrixPageState();
}

class _ConfusionMatrixPageState extends State<ConfusionMatrixPage> {
  late ConfusionMatrixService _service;
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _service = ConfusionMatrixService();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    _metrics = await _service.calculateMetrics();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Performance'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_metrics['hasData']
              ? const Center(child: Text('No data yet. Make some detections first!'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Overall Accuracy',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${_metrics['accuracy']}%',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMetric('Precision', '${_metrics['avgPrecision']}%'),
                                  _buildMetric('Recall', '${_metrics['avgRecall']}%'),
                                  _buildMetric('F1 Score', '${_metrics['avgF1']}%'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Total Detections',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${_metrics['totalSamples']}',
                                style: const TextStyle(
                                  fontSize: 32,
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
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
