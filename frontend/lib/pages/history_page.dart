import 'dart:io';
import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../services/export_service.dart';
import '../services/translation_service.dart';
import '../widgets/language_selector.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService();
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _historyService.getPredictions();
    setState(() {
      _predictions = history;
      _isLoading = false;
    });
  }

  Future<void> _exportHistory() async {
    try {
      final service = ExportService();
      final file = await service.exportToCSV();

      if (!mounted) return;

      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TranslationService.translate('no_data_export'))),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${TranslationService.translate('exported')}: ${file.path}")),
      );

      await service.exportAndShare();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${TranslationService.translate('export_failed')}: $e")),
      );
    }
  }

  Future<void> _deletePrediction(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(
        title: TranslationService.translate('confirm_delete'),
        content: TranslationService.translate('delete_prediction_confirm'),
      ),
    );

    if (confirm != true || !mounted) return;

    await _historyService.deletePrediction(id);
    await _loadHistory();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationService.translate('history_deleted')),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    if (_predictions.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(
        title: TranslationService.translate('clear_all'),
        content: TranslationService.translate('clear_all_confirm'),
      ),
    );

    if (confirm != true || !mounted) return;

    await _historyService.clearHistory();
    await _loadHistory();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationService.translate('all_history_cleared')),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildDeleteDialog({required String title, required String content}) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(TranslationService.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(TranslationService.translate('delete')),
        ),
      ],
    );
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _getCropIcon(String crop) {
    switch (crop.toLowerCase()) {
      case 'maize':
        return Icon(Icons.grass, size: 18, color: Colors.amber[700]);
      case 'tomato':
        return Icon(Icons.circle, size: 18, color: Colors.red);
      case 'potato':
        return Icon(Icons.circle, size: 18, color: Colors.brown);
      case 'wheat':
        return Icon(Icons.eco, size: 18, color: Colors.orange);
      case 'rice':
        return Icon(Icons.grain, size: 18, color: Colors.lightGreen);
      default:
        return Icon(Icons.agriculture, size: 18, color: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TranslationService.instance,
      builder: (context, child) {
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
                          TranslationService.translate('detection_history'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const LanguageSelector(),
                        if (_predictions.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete_sweep, color: Colors.white),
                            onPressed: _clearAllHistory,
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _predictions.isEmpty
                              ? _buildEmptyState()
                              : _buildHistoryList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            TranslationService.translate('no_history'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            TranslationService.translate('empty_history_hint'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.camera_alt),
            label: Text(TranslationService.translate('go_to_camera')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        final item = _predictions[index];
        final id = (item['id'] as int?) ?? 0;
        final crop = item['crop'] ?? 'Unknown';
        final disease = item['disease'] ?? 'Unknown';
        final confidence = (item['confidence'] as num?)?.toDouble() ?? 0.0;
        final treatment = item['treatment'] ?? '';
        final timestamp = item['timestamp'] ?? '';
        final imagePath = item['imagePath'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    _getCropIcon(crop),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        crop.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, size: 18, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            disease,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${TranslationService.translate('confidence')}: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: confidence / 100,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              color: _getConfidenceColor(confidence),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${confidence.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getConfidenceColor(confidence),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.medical_services, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            treatment.length > 60 ? '${treatment.substring(0, 60)}...' : treatment,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                          onPressed: () => _deletePrediction(id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.green),
                          onPressed: _exportHistory,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showDetailDialog(item),
                          icon: Icon(Icons.visibility, size: 18, color: Colors.green[600]),
                          label: Text(
                            TranslationService.translate('view_details'),
                            style: TextStyle(color: Colors.green[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetailDialog(Map<String, dynamic> item) {
    final crop = item['crop'] ?? 'Unknown';
    final disease = item['disease'] ?? 'Unknown';
    final confidence = (item['confidence'] as num?)?.toDouble() ?? 0.0;
    final treatment = item['treatment'] ?? '';
    final timestamp = item['timestamp'] ?? '';
    final imagePath = item['imagePath'] ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getCropIcon(crop),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      crop.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              if (imagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                disease,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: confidence / 100,
                backgroundColor: Colors.grey.shade200,
                color: _getConfidenceColor(confidence),
              ),
              const SizedBox(height: 8),
              Text('${confidence.toStringAsFixed(1)}% ${TranslationService.translate('confidence')}'),
              const SizedBox(height: 16),
              Text(
                '${TranslationService.translate('treatment')}:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
              const SizedBox(height: 4),
              Text(treatment),
              const SizedBox(height: 16),
              Text(
                _formatDate(timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}