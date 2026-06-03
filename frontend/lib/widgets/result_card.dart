import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/device_tts_service.dart';
import '../services/translation_service.dart';

class ResultCard extends StatelessWidget {
  final String disease;
  final double confidence;
  final String treatment;
  final String imagePath;
  final String Function(double) getSeverityLabel;
  final String? geminiAdvice;

  const ResultCard({
    super.key,
    required this.disease,
    required this.confidence,
    required this.treatment,
    required this.imagePath,
    required this.getSeverityLabel,
    this.geminiAdvice,
  });

  void _shareResult(BuildContext context) {
    final String shareText = '''
🌾 CROP DISEASE DETECTION RESULT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Disease: $disease
📊 Confidence: ${confidence.toStringAsFixed(1)}%
⚠️ Severity: ${getSeverityLabel(confidence)}

💊 Treatment:
$treatment

${geminiAdvice != null && geminiAdvice!.isNotEmpty ? '🤖 AI Expert Advice:\n$geminiAdvice\n' : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 AI-Powered Crop Disease Detection App
''';
    
    Share.share(shareText);
  }

  Future<void> _speakResult(BuildContext context) async {
    final isAmharic = TranslationService.isAmharic;
    final tts = DeviceTTSService();
    await tts.init();
    
    await tts.speakResult(
      {
        'disease': disease,
        'confidence': confidence.toStringAsFixed(1),
        'treatment': treatment,
      },
      isAmharic ? 'am' : 'en',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.isNotEmpty;
    final hasGeminiAdvice = geminiAdvice != null && geminiAdvice!.isNotEmpty;
    final isAmharic = TranslationService.isAmharic;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Share and Speaker Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detection Result',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Row(
                children: [
                  // Speaker button for voice output
                  IconButton(
                    onPressed: () => _speakResult(context),
                    icon: const Icon(Icons.volume_up, color: Colors.blue),
                    tooltip: isAmharic ? 'ውጤቱን ያንብቡ' : 'Read Result Aloud',
                  ),
                  // Share button
                  IconButton(
                    onPressed: () => _shareResult(context),
                    icon: const Icon(Icons.share, color: Colors.green),
                    tooltip: 'Share Result',
                  ),
                ],
              ),
            ],
          ),
          const Divider(),

          if (hasImage) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(imagePath),
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ],

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  disease,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          LinearProgressIndicator(
            value: (confidence.clamp(0, 100)) / 100,
            minHeight: 12,
            backgroundColor: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Severity: ${getSeverityLabel(confidence)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Icon(
                Icons.medical_services,
                color: Colors.green,
              ),
              const SizedBox(width: 10),
              const Text(
                'Treatment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              treatment,
              style: const TextStyle(
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ),
          
          // GEMINI AI ADVICE SECTION
          if (hasGeminiAdvice) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.purple,
                ),
                const SizedBox(width: 10),
                const Text(
                  'AI Expert Advice',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Text(
                geminiAdvice!,
                style: const TextStyle(
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Share Button at bottom
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareResult(context),
              icon: const Icon(Icons.share),
              label: const Text('Share Result'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
