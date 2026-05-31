import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ResultCard extends StatelessWidget {
  final String disease;
  final double confidence;
  final String treatment;
  final String imagePath;
  final String Function(double) getSeverityLabel;

  const ResultCard({
    super.key,
    required this.disease,
    required this.confidence,
    required this.treatment,
    required this.imagePath,
    required this.getSeverityLabel,
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

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 AI-Powered Crop Disease Detection App
''';
    
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.isNotEmpty;

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
          // Header with Share Button
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
              IconButton(
                onPressed: () => _shareResult(context),
                icon: const Icon(Icons.share, color: Colors.green),
                tooltip: 'Share Result',
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