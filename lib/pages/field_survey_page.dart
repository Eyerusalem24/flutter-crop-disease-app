import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/field_survey_service.dart';

class FieldSurveyPage extends StatefulWidget {
  final CameraDescription camera;
  
  const FieldSurveyPage({super.key, required this.camera});

  @override
  State<FieldSurveyPage> createState() => _FieldSurveyPageState();
}

class _FieldSurveyPageState extends State<FieldSurveyPage> {
  late CameraService _cameraService;
  final ApiService _apiService = ApiService();
  final HistoryService _historyService = HistoryService();
  final FieldSurveyService _surveyService = FieldSurveyService();
  
  bool _cameraReady = false;
  bool _isSurveying = false;
  bool _isProcessing = false;
  bool _isFinishing = false;
  
  String _fieldName = '';
  String _selectedCropForSurvey = 'maize';
  final TextEditingController _fieldNameController = TextEditingController();
  
  List<Map<String, dynamic>> _surveyResults = [];
  int _photoCount = 0;
  int _healthyCount = 0;
  int _diseasedCount = 0;
  Map<String, int> _diseaseCount = {};

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameraService = CameraService(widget.camera);
    await _cameraService.initialize();
    if (mounted) {
      setState(() => _cameraReady = true);
    }
  }

  Future<void> _startSurvey() async {
    if (_fieldNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a field name')),
      );
      return;
    }
    
    setState(() {
      _fieldName = _fieldNameController.text;
      _isSurveying = true;
      _surveyResults = [];
      _photoCount = 0;
      _healthyCount = 0;
      _diseasedCount = 0;
      _diseaseCount = {};
    });
  }

  Future<void> _takePhoto() async {
    if (_photoCount >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 20 photos reached'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (!_cameraReady) return;
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final imagePath = await _cameraService.captureImage();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analyzing photo ${_photoCount + 1}/20...'), duration: const Duration(seconds: 1)),
      );
      
      final result = await _apiService.predict(
        imagePath: imagePath,
        crop: _selectedCropForSurvey,
      );
      
      final disease = result['disease'];
      final isHealthy = disease.toLowerCase().contains('healthy');
      
      setState(() {
        _surveyResults.add({
          'imagePath': imagePath,
          'disease': disease,
          'confidence': result['confidence'],
          'isHealthy': isHealthy,
          'timestamp': DateTime.now(),
        });
        
        _photoCount++;
        
        if (isHealthy) {
          _healthyCount++;
        } else {
          _diseasedCount++;
          _diseaseCount[disease] = (_diseaseCount[disease] ?? 0) + 1;
        }
        
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isHealthy ? "✅ Healthy" : "⚠️ $disease"}'),
          backgroundColor: isHealthy ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 1),
        ),
      );
      
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _finishSurvey() async {
    if (_photoCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take at least 1 photo before finishing'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_isFinishing) return;
    
    setState(() => _isFinishing = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving survey results...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      await _surveyService.saveSurveySession(
        fieldName: _fieldName,
        date: DateTime.now(),
        totalPhotos: _photoCount,
        healthyCount: _healthyCount,
        diseasedCount: _diseasedCount,
        diseaseBreakdown: _diseaseCount,
      );
      
      for (var result in _surveyResults) {
        await _historyService.savePrediction({
          'crop': _selectedCropForSurvey,
          'disease': result['disease'],
          'confidence': result['confidence'],
          'treatment': 'See field survey report',
          'imagePath': result['imagePath'],
          'timestamp': result['timestamp'].toIso8601String(),
        });
      }
      
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        setState(() {
          _isSurveying = false;
          _isFinishing = false;
        });
        
        _showSurveySummary();
      }
      
    } catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving survey: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSurveySummary() {
    final healthRate = _photoCount > 0 ? (_healthyCount / _photoCount * 100).toStringAsFixed(1) : '0';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✅ Survey Complete!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📍 Field: $_fieldName', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('🌽 Crop: ${_selectedCropForSurvey.toUpperCase()}'),
              const Divider(),
              const SizedBox(height: 8),
              Text('📸 Photos taken: $_photoCount'),
              const SizedBox(height: 4),
              Text('✅ Healthy plants: $_healthyCount'),
              Text('❌ Diseased plants: $_diseasedCount'),
              const SizedBox(height: 12),
              if (_diseaseCount.isNotEmpty) ...[
                const Text('🦠 Disease Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ..._diseaseCount.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('• ${e.key}: ${e.value} plants'),
                )),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: double.parse(healthRate) > 70 ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      double.parse(healthRate) > 70 ? Icons.health_and_safety : Icons.warning,
                      color: double.parse(healthRate) > 70 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Health Rate: $healthRate%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: double.parse(healthRate) > 70 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewSurveyHistory() async {
    final sessions = await _surveyService.getSessionsForField(_fieldName);
    
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No survey history for this field')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$_fieldName - Survey History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final date = DateTime.parse(session['date'] as String);
              return ListTile(
                title: Text('${date.day}/${date.month}/${date.year}'),
                subtitle: Text('${session['totalPhotos']} photos, ${session['healthyCount']} healthy'),
                trailing: Chip(
                  label: Text('${((session['healthyCount'] as int) / (session['totalPhotos'] as int) * 100).toInt()}%'),
                  backgroundColor: Colors.green.shade100,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fieldNameController.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              // Compact App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      _isSurveying ? 'Survey' : 'Field Survey',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (_isSurveying)
                      Text(
                        '$_photoCount/20',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    if (!_isSurveying && _fieldName.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.white, size: 22),
                        onPressed: _viewSurveyHistory,
                      ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: !_isSurveying
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.agriculture, size: 50, color: Colors.green),
                              const SizedBox(height: 12),
                              const Text(
                                'Field Disease Survey',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Take up to 20 photos',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 20),
                              
                              TextField(
                                controller: _fieldNameController,
                                decoration: InputDecoration(
                                  labelText: 'Field Name',
                                  hintText: 'e.g., North Field',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              DropdownButtonFormField<String>(
                                value: _selectedCropForSurvey,
                                decoration: InputDecoration(
                                  labelText: 'Crop Type',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                items: ['maize', 'tomato', 'potato', 'wheat', 'rice'].map((crop) {
                                  return DropdownMenuItem(
                                    value: crop,
                                    child: Text(crop.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedCropForSurvey = value;
                                    });
                                  }
                                },
                              ),
                              
                              const SizedBox(height: 20),
                              
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _startSurvey,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text('Start Survey', style: TextStyle(fontSize: 14)),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        )
                      : _buildSurveyScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyScreen() {
    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _photoCount / 20,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_photoCount / 20 photos', style: const TextStyle(fontSize: 11)),
                  Text('${(_photoCount / 20 * 100).toInt()}%', style: const TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        
        // Camera preview
        Expanded(
          child: _cameraReady
              ? CameraPreview(_cameraService.controller)
              : const Center(child: CircularProgressIndicator()),
        ),
        
        // Quick stats during survey
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip(Icons.check_circle, 'Healthy', _healthyCount, Colors.green),
              _buildStatChip(Icons.warning, 'Diseased', _diseasedCount, Colors.red),
              _buildStatChip(Icons.photo_camera, 'Taken', _photoCount, Colors.blue),
            ],
          ),
        ),
        
        // Buttons
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isProcessing || _isFinishing) ? null : _takePhoto,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera, size: 18),
                  label: Text(_isProcessing ? 'Analyzing...' : 'Take Photo', style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: (_isProcessing || _isFinishing) ? null : _finishSurvey,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(_isFinishing ? 'Saving...' : 'Finish', style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        
        // Instruction text
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Take photos of different plants',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text('$label: $count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}