import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';

import '../widgets/result_card.dart';
import '../widgets/language_selector.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/history_service.dart';
import '../services/permission_service.dart';
import '../services/analytics_service.dart';
import '../services/translation_service.dart';
import 'package:share_plus/share_plus.dart';

class DetectionPage extends StatefulWidget {
  final CameraDescription camera;

  const DetectionPage({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage>
    with WidgetsBindingObserver {
  CameraService? _cameraService;

  final ApiService _apiService = ApiService();
  final HistoryService _historyService = HistoryService();
  final FlutterTts _flutterTts = FlutterTts();

  bool _processing = false;
  bool _cameraReady = false;

  final List<String> _crops = [
    'maize',
    'tomato',
    'potato',
    'wheat',
    'rice'
  ];

  String _selectedCrop = 'maize';

  String _resultDisease = '';
  double _resultConfidence = 0;
  String _resultTreatment = '';
  String _geminiAdvice = '';
  String _lastImagePath = '';

  String? _errorMessage;

  // Amharic translations for diseases
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

  // Amharic translations for treatments
  final Map<String, String> _treatmentAm = {
    'Gray Leaf Spot': 'ፈንገስ ተከላካይ መድሀኒት ይጠቀሙ።',
    'Common Rust': 'ተከላካይ ዝርያዎችን ይጠቀሙ።',
    'Northern Leaf Blight': 'ሰብል ያሽከርክሩ።',
    'Healthy': 'ሰብልዎ ጤናማ ነው!',
    'Late Blight': 'የበሽታውን ቅጠሎች ያስወግዱ።',
    'Early Blight': 'የታችኞቹን ቅጠሎች ይቁረጡ።',
    'Leaf Mold': 'የአየር ዝውውርን ያሻሽሉ።',
    'Septoria Leaf Spot': 'የበሽታውን ቅጠሎች ያስወግዱ።',
    'Stripe Rust': 'ተከላካይ ዝርያዎችን ይጠቀሙ።',
    'Leaf Rust': 'ፈንገስ ተከላካይ ይጠቀሙ።',
    'Stem Rust': 'የሸምበቆ ቅጠል ስርጭትን ያጥፉ።',
    'Blast': 'ተከላካይ ዝርያዎችን ይጠቀሙ።',
    'Blight': 'እርሻዎችን ያፈስሱ።',
    'Sheath Rot': 'ፈንገስ ተከላካይ ይጠቀሙ።',
  };

  // Amharic translations for crop names
  final Map<String, String> _cropAm = {
    'maize': 'በቆሎ',
    'tomato': 'ቲማቲም',
    'potato': 'ድንች',
    'wheat': 'ስንዴ',
    'rice': 'ሩዝ',
  };

  Future<void> _generateTestData() async {
    final historyService = HistoryService();
    final List<String> testDiseases = [
      'Common Rust', 'Gray Leaf Spot', 'Northern Leaf Blight', 'Healthy',
      'Late Blight', 'Early Blight', 'Leaf Mold', 'Stripe Rust', 'Blast',
      'Common Rust', 'Gray Leaf Spot', 'Late Blight', 'Common Rust'
    ];
    final List<String> testCrops = ['maize', 'tomato', 'potato', 'wheat', 'rice'];
    
    for (int i = 0; i < 15; i++) {
      await historyService.savePrediction({
        'crop': testCrops[i % testCrops.length],
        'disease': testDiseases[i % testDiseases.length],
        'confidence': 70.0 + (i * 2),
        'treatment': 'Test treatment',
        'imagePath': '',
        'timestamp': DateTime.now().subtract(Duration(days: i % 7)).toIso8601String(),
      });
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 15 test records added! Go to Analytics Dashboard')),
      );
    }
  }

  Future<void> _checkCameraAvailability() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        _showError("No camera found on this device");
        return;
      }
    } catch (e) {
      print("❌ Camera check failed: $e");
      _showError("Camera error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final hasPermission = await PermissionService.requestCameraPermission();

    if (!hasPermission) {
      _showError("Camera permission is required for this app");
      return;
    }

    await _checkCameraAvailability();
    await _initCamera();
    await _initTts();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_cameraReady) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (!mounted) return;

    setState(() {
      _cameraReady = false;
    });

    try {
      final service = CameraService(widget.camera);
      await service.initialize();

      if (!mounted) return;

      setState(() {
        _cameraService = service;
        _cameraReady = true;
      });

      print("✅ Camera initialized successfully");
    } catch (e) {
      print("❌ Camera initialization error: $e");
      if (!mounted) return;
      _showError("Cannot access camera. Please check permissions.");
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    final isAmharic = TranslationService.isAmharic;
    await _flutterTts.setLanguage(isAmharic ? 'am-ET' : 'en-US');
    await _flutterTts.speak(text);
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
      _processing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _clearError() {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
    });
  }

  String _getSeverityLabel(double confidence) {
    final isAmharic = TranslationService.isAmharic;
    if (confidence >= 90) return isAmharic ? 'ትንሽ' : 'Low';
    if (confidence >= 70) return isAmharic ? 'መካከለኛ' : 'Moderate';
    if (confidence >= 50) return isAmharic ? 'ከፍተኛ' : 'High';
    return isAmharic ? 'ከባድ' : 'Severe';
  }

  Widget _getCropIcon(String crop) {
    switch (crop) {
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

  Future<void> _captureAndDetect() async {
    if (!_cameraReady || _cameraService == null) {
      _showError("Camera not ready. Please wait.");
      return;
    }

    setState(() {
      _processing = true;
      _errorMessage = null;
    });

    try {
      final imagePath = await _cameraService!.captureImage();
      _lastImagePath = imagePath;

      final result = await _apiService.predict(
        imagePath: imagePath,
        crop: _selectedCrop,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception("API timeout after 30 seconds"),
      );

      final diseaseEn = result['disease'];
      final confidence = result['confidence'];
      final treatment = result['treatment'];
      final geminiAdvice = result['gemini_advice'] ?? '';
      final isAmharic = TranslationService.isAmharic;

      if (!mounted) return;

      setState(() {
        _resultDisease = isAmharic ? (_diseaseAm[diseaseEn] ?? diseaseEn) : diseaseEn;
        _resultConfidence = confidence.toDouble();
        _resultTreatment = isAmharic ? (_treatmentAm[diseaseEn] ?? treatment) : treatment;
        _geminiAdvice = geminiAdvice;
        _processing = false;
      });

      await _historyService.savePrediction({
        'crop': _selectedCrop,
        'disease': _resultDisease,
        'confidence': _resultConfidence,
        'treatment': _resultTreatment,
        'imagePath': _lastImagePath,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _speak(isAmharic ? 'በሽታ ተገኝቷል' : 'Disease detected');
    } catch (e) {
      print("❌ Detection error: $e");
      if (!mounted) return;
      setState(() { _processing = false; });
      _showError("Detection failed: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      _processing = true;
      _lastImagePath = picked.path;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.predict(
        imagePath: picked.path,
        crop: _selectedCrop,
      );

      final diseaseEn = result['disease'];
      final confidence = result['confidence'];
      final treatment = result['treatment'];
      final geminiAdvice = result['gemini_advice'] ?? '';
      final isAmharic = TranslationService.isAmharic;

      if (!mounted) return;

      setState(() {
        _resultDisease = isAmharic ? (_diseaseAm[diseaseEn] ?? diseaseEn) : diseaseEn;
        _resultConfidence = confidence.toDouble();
        _resultTreatment = isAmharic ? (_treatmentAm[diseaseEn] ?? treatment) : treatment;
        _geminiAdvice = geminiAdvice;
        _processing = false;
      });

      await _historyService.savePrediction({
        'crop': _selectedCrop,
        'disease': _resultDisease,
        'confidence': _resultConfidence,
        'treatment': _resultTreatment,
        'imagePath': _lastImagePath,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _speak(isAmharic ? 'በሽታ ተገኝቷል' : 'Disease detected');
    } catch (e) {
      print("❌ Gallery error: $e");
      _showError("Analysis failed: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TranslationService.instance,
      builder: (context, child) {
        final isAmharic = TranslationService.isAmharic;
        final hasResult = _resultDisease.isNotEmpty && _resultConfidence > 0;
        final screenWidth = MediaQuery.of(context).size.width;

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
                        const Text(
                          'Crop Doctor',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.agriculture, size: 20, color: Colors.green[700]),
                                const SizedBox(width: 8),
                                Text(
                                  isAmharic ? 'የሰብል አይነት ይምረጡ' : 'Select Crop Type',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _crops.map((crop) {
                                final isSelected = _selectedCrop == crop;
                                return FilterChip(
                                  avatar: _getCropIcon(crop),
                                  label: Text(
                                    isAmharic
                                        ? (_cropAm[crop] ?? crop.toUpperCase())
                                        : crop.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.green[800],
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: _processing ? null : (selected) {
                                    if (selected) {
                                      setState(() => _selectedCrop = crop);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isAmharic
                                                ? '${_cropAm[crop] ?? crop.toUpperCase()} ተመርጧል'
                                                : '${crop.toUpperCase()} selected',
                                          ),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  backgroundColor: Colors.grey.shade100,
                                  selectedColor: Colors.green,
                                  checkmarkColor: Colors.white,
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: isSelected ? Colors.green : Colors.grey.shade300,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt, size: 18, color: Colors.green[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAmharic ? 'ምስል ይያዙ' : 'Take a Photo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: !_cameraReady
                                  ? Container(
                                      width: screenWidth - 48,
                                      height: 300,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.videocam_off, size: 48, color: Colors.grey.shade600),
                                            const SizedBox(height: 12),
                                            Text(
                                              isAmharic ? 'ካሜራ አይገኝም' : 'Camera not available',
                                              style: TextStyle(color: Colors.grey.shade600),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: _initCamera,
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                              child: Text(isAmharic ? 'እንደገና ይሞክሩ' : 'Retry'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: SizedBox(
                                        width: screenWidth - 48,
                                        height: 320,
                                        child: _cameraService == null
                                            ? const Center(child: CircularProgressIndicator())
                                            : CameraPreview(_cameraService!.controller),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _processing ? null : _captureAndDetect,
                                    icon: const Icon(Icons.camera, size: 20),
                                    label: Text(isAmharic ? 'ፎቶ ያንሱ' : 'Capture'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImageFromGallery,
                                    icon: const Icon(Icons.photo_library, size: 20),
                                    label: Text(isAmharic ? 'ማህደር' : 'Gallery'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green,
                                      side: BorderSide(color: Colors.green),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_errorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.red),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(_errorMessage!)),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: _clearError,
                                    ),
                                  ],
                                ),
                              ),
                            if (_processing)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 12),
                                    Text("Analyzing crop image..."),
                                  ],
                                ),
                              ),
                            if (hasResult && !_processing)
                              ResultCard(
                                disease: _resultDisease,
                                confidence: _resultConfidence,
                                treatment: _resultTreatment,
                                imagePath: _lastImagePath,
                                geminiAdvice: _geminiAdvice,
                                getSeverityLabel: _getSeverityLabel,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _generateTestData,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}