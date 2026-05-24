import 'dart:io';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.green.shade100, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(imagePath),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 20),

          // Disease name + confidence
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  disease,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Confidence bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (confidence.clamp(0, 100)) / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: confidence >= 70 ? Colors.green : Colors.orange,
            ),
          ),

          const SizedBox(height: 20),

          // Severity
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Severity: ${getSeverityLabel(confidence)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Treatment section
          Row(
            children: [
              Icon(Icons.medical_services, color: Colors.green.shade600),
              const SizedBox(width: 10),
              const Text(
                'Recommended Treatment',
                style: TextStyle(
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
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              treatment,
              style: const TextStyle(
                height: 1.5,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}