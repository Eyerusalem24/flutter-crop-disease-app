import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../services/history_service.dart';
import 'detection_page.dart';

class FieldSurveyPage extends StatefulWidget {
  final CameraDescription camera;
  const FieldSurveyPage({super.key, required this.camera});

  @override
  State<FieldSurveyPage> createState() => _FieldSurveyPageState();
}

class _FieldSurveyPageState extends State<FieldSurveyPage> {
  final ApiService _apiService = ApiService();
  final HistoryService _historyService = HistoryService();
  
  String _fieldName = '';
  int _photoCount = 0;
  int _healthyCount = 0;
  int _diseasedCount = 0;
  Map<String, int> _diseaseCount = {};
  List<Map<String, dynamic>> _detections = [];
  
  bool _isSurveying = false;
  bool _isProcessing = false;

  Future<void> _startSurvey() async {
    if (_fieldName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter field name')),
      );
      return;
    }
    
    setState(() {
      _isSurveying = true;
      _photoCount = 0;
      _healthyCount = 0;
      _diseasedCount = 0;
      _diseaseCount = {};
      _detections = [];
    });
    
    _takePhoto();
  }

  Future<void> _takePhoto() async {
    if (!_isSurveying) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetectionPage(camera: widget.camera),
      ),
    );
    
    if (result != null && mounted) {
      final isAmharic = TranslationService.isAmharic;
      final disease = result['disease'];
      final confidence = result['confidence'];
      final treatment = result['treatment'];
      final imagePath = result['imagePath'];
      
      setState(() {
        _photoCount++;
        if (disease == 'Healthy' || disease == 'ጤናማ') {
          _healthyCount++;
        } else {
          _diseasedCount++;
          _diseaseCount[disease] = (_diseaseCount[disease] ?? 0) + 1;
        }
        _detections.add({
          'disease': disease,
          'confidence': confidence,
          'treatment': treatment,
          'imagePath': imagePath,
        });
      });
      
      // Show continue dialog
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isAmharic ? 'ቀጥል?' : 'Continue?'),
          content: Text(isAmharic 
              ? '${_photoCount} ፎቶዎች ተወስደዋል። መቀጠል ይፈልጋሉ?'
              : '$_photoCount photos taken. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAmharic ? 'አቁም' : 'Stop'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isAmharic ? 'ቀጥል' : 'Continue'),
            ),
          ],
        ),
      );
      
      if (shouldContinue == true && mounted) {
        _takePhoto();
      } else {
        _endSurvey();
      }
    }
  }

  Future<void> _endSurvey() async {
    setState(() => _isProcessing = true);
    
    // Save survey results
    final isAmharic = TranslationService.isAmharic;
    
    for (var detection in _detections) {
      await _historyService.savePrediction({
        'crop': 'survey',
        'disease': detection['disease'],
        'confidence': detection['confidence'],
        'treatment': detection['treatment'],
        'imagePath': detection['imagePath'],
        'timestamp': DateTime.now().toIso8601String(),
        'fieldName': _fieldName,
        'surveyType': 'field_survey',
      });
    }
    
    setState(() {
      _isSurveying = false;
      _isProcessing = false;
    });
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isAmharic ? 'የመስክ ቅኝት ተጠናቋል' : 'Field Survey Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${isAmharic ? 'ጠቅላላ ፎቶዎች' : 'Total Photos'}: $_photoCount'),
              Text('${isAmharic ? 'ጤናማ' : 'Healthy'}: $_healthyCount'),
              Text('${isAmharic ? 'በሽታ ያለባቸው' : 'Diseased'}: $_diseasedCount'),
              const SizedBox(height: 8),
              Text(isAmharic ? 'በሽታ ስርጭት:' : 'Disease Distribution:'),
              ..._diseaseCount.entries.map((e) => Text('  ${e.key}: ${e.value}')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isAmharic ? 'ዝጋ' : 'Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAmharic = TranslationService.isAmharic;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isAmharic ? 'የመስክ ቅኝት' : 'Field Survey'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: isAmharic ? 'የሜዳ ስም' : 'Field Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.agriculture),
              ),
              onChanged: (value) => _fieldName = value,
              enabled: !_isSurveying && !_isProcessing,
            ),
            const SizedBox(height: 24),
            if (_isSurveying) ...[
              LinearProgressIndicator(
                value: _photoCount / 30,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 16),
              Text(
                isAmharic ? 'ፎቶዎች: $_photoCount / 30' : 'Photos: $_photoCount / 30',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _endSurvey(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(isAmharic ? 'ቅኝት አቁም' : 'Stop Survey'),
              ),
            ] else if (_isProcessing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(
                isAmharic ? 'ውጤቶችን በማስቀመጥ ላይ...' : 'Saving results...',
                textAlign: TextAlign.center,
              ),
            ] else ...[
              if (_photoCount == 0)
                ElevatedButton(
                  onPressed: _fieldName.isEmpty ? null : _startSurvey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(isAmharic ? 'ቅኝት ጀምር' : 'Start Survey'),
                ),
            ],
            const SizedBox(height: 24),
            if (_detections.isNotEmpty && !_isSurveying && !_isProcessing)
              Expanded(
                child: ListView.builder(
                  itemCount: _detections.length,
                  itemBuilder: (context, index) {
                    final detection = _detections[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: detection['disease'] == 'Healthy' 
                              ? Colors.green 
                              : Colors.red,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(detection['disease']),
                        subtitle: Text('${detection['confidence'].toStringAsFixed(1)}%'),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Image.file(
                                  File(detection['imagePath']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
