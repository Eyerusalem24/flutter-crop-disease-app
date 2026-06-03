import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/device_tts_service.dart';
import '../services/translation_service.dart';
import '../services/fertilizer_service.dart';
import '../services/api_service.dart';

class ResultCard extends StatelessWidget {
  final String disease;
  final double confidence;
  final String treatment;
  final String imagePath;
  final String Function(double) getSeverityLabel;
  final String? geminiAdvice;
  final String? heatmapUrl;

  const ResultCard({
    super.key,
    required this.disease,
    required this.confidence,
    required this.treatment,
    required this.imagePath,
    required this.getSeverityLabel,
    this.geminiAdvice,
    this.heatmapUrl,
  });

  void _shareResult(BuildContext context) {
    final isAmharic = TranslationService.isAmharic;
    final fertilizerRec = FertilizerService.getFertilizerRecommendation(disease, isAmharic ? 'am' : 'en');
    
    final String shareText = '''
🌾 CROP DISEASE DETECTION RESULT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Disease: $disease
📊 Confidence: ${confidence.toStringAsFixed(1)}%
⚠️ Severity: ${getSeverityLabel(confidence)}

💊 Treatment:
$treatment

🌱 FERTILIZER RECOMMENDATION:
📌 Fertilizer: ${fertilizerRec['fertilizer']}
📌 Application: ${fertilizerRec['application']}
📌 Organic Alternative: ${fertilizerRec['organic_alternative']}
📌 Timing: ${fertilizerRec['timing']}
📌 Frequency: ${fertilizerRec['frequency']}
📌 Precautions: ${fertilizerRec['precautions']}

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
    
    final fertilizerRec = FertilizerService.getFertilizerRecommendation(disease, isAmharic ? 'am' : 'en');
    
    final fullText = isAmharic
        ? 'የበሽታ ውጤት። '
            'በሽታ፦ $disease። '
            'እምነት፦ ${confidence.toStringAsFixed(1)} በመቶ። '
            'ህክምና፦ $treatment። '
            'ማዳበሪያ ምክር፦ ${fertilizerRec['fertilizer']}። '
            'አፕሊኬሽን፦ ${fertilizerRec['application']}። '
            'ኦርጋኒክ አማራጭ፦ ${fertilizerRec['organic_alternative']}። '
            'ጊዜ፦ ${fertilizerRec['timing']}። '
            'ድግግሞሽ፦ ${fertilizerRec['frequency']}። '
            'ጥንቃቄዎች፦ ${fertilizerRec['precautions']}።'
        : 'Detection result. '
            'Disease: $disease. '
            'Confidence: ${confidence.toStringAsFixed(1)} percent. '
            'Treatment: $treatment. '
            'Fertilizer: ${fertilizerRec['fertilizer']}. '
            'Application: ${fertilizerRec['application']}. '
            'Organic alternative: ${fertilizerRec['organic_alternative']}. '
            'Timing: ${fertilizerRec['timing']}. '
            'Frequency: ${fertilizerRec['frequency']}. '
            'Precautions: ${fertilizerRec['precautions']}.';
    
    await tts.speak(fullText, language: isAmharic ? 'am' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.isNotEmpty;
    final hasGeminiAdvice = geminiAdvice != null && geminiAdvice!.isNotEmpty;
    final hasHeatmap = heatmapUrl != null && heatmapUrl!.isNotEmpty;
    final isAmharic = TranslationService.isAmharic;
    final fertilizerRec = FertilizerService.getFertilizerRecommendation(disease, isAmharic ? 'am' : 'en');

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
                  IconButton(
                    onPressed: () => _speakResult(context),
                    icon: const Icon(Icons.volume_up, color: Colors.blue),
                    tooltip: isAmharic ? 'ውጤቱን ያንብቡ' : 'Read Result Aloud',
                  ),
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

          // Original Image
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

          // HEATMAP SECTION (AI Focus Areas)
          if (hasHeatmap) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        isAmharic ? 'AI ትኩረት አካባቢዎች' : 'AI Focus Areas (Heatmap)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      '${ApiService().baseUrl}$heatmapUrl',
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Heatmap image error: $error');
                        return Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Text('Heatmap loading failed'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAmharic ? 'ቀይ: AI ትኩረት ያደረገባቸው ቦታዎች' : 'Red = Key features AI focused on',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAmharic ? 'ሰማያዊ: አነስተኛ ጠቀሜታ' : 'Blue = Less relevant areas',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
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

          // Treatment Section
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
          
          // Fertilizer Recommendation Section
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.grass,
                color: Colors.brown,
              ),
              const SizedBox(width: 10),
              Text(
                isAmharic ? 'የማዳበሪያ ምክር' : 'Fertilizer Recommendation',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.brown.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.brown.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFertilizerRow(isAmharic ? 'ማዳበሪያ' : 'Fertilizer', fertilizerRec['fertilizer']),
                const SizedBox(height: 8),
                _buildFertilizerRow(isAmharic ? 'አፕሊኬሽን' : 'Application', fertilizerRec['application']),
                const SizedBox(height: 8),
                _buildFertilizerRow(isAmharic ? 'ኦርጋኒክ አማራጭ' : 'Organic Alternative', fertilizerRec['organic_alternative']),
                const SizedBox(height: 8),
                _buildFertilizerRow(isAmharic ? 'ጊዜ' : 'Timing', fertilizerRec['timing']),
                const SizedBox(height: 8),
                _buildFertilizerRow(isAmharic ? 'ድግግሞሽ' : 'Frequency', fertilizerRec['frequency']),
                const SizedBox(height: 8),
                _buildFertilizerRow(isAmharic ? 'ጥንቃቄዎች' : 'Precautions', fertilizerRec['precautions']),
              ],
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
                Text(
                  isAmharic ? 'AI የባለሙያ ምክር' : 'AI Expert Advice',
                  style: const TextStyle(
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

  Widget _buildFertilizerRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
