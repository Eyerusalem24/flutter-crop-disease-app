import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'history_service.dart';


class ExportService {
  final HistoryService _historyService = HistoryService();

 Future<File?> exportToCSV() async {
  try {
    final predictions = await _historyService.getPredictions(limit: 1000);
    if (predictions.isEmpty) return null;

    List<List<dynamic>> csvData = [];
    csvData.add(['ID', 'Crop', 'Disease', 'Confidence (%)', 'Treatment', 'Date', 'Time']);

    for (var p in predictions) {
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(p['timestamp']);
      } catch (_) {
        timestamp = DateTime.now();
      }

      csvData.add([
        p['id'] ?? '',
        p['crop'] ?? '',
        p['disease'] ?? '',
        (p['confidence'] as num?)?.toStringAsFixed(1) ?? '0',
        p['treatment'] ?? '',
        '${timestamp.year}-${timestamp.month}-${timestamp.day}',
        '${timestamp.hour}:${timestamp.minute}:${timestamp.second}',
      ]);
    }

    final String csv = ListToCsvConverter().convert(csvData);

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/crop_disease_history_${DateTime.now().millisecondsSinceEpoch}.csv';

    final File file = File(filePath);
    await file.writeAsString(csv);

    return file;
  } catch (e) {
    print("Export error: $e");
    return null;
  }
}
  
  Future<bool> exportAndShare() async {
    final file = await exportToCSV();
    if (file == null) return false;
    await Share.shareXFiles([XFile(file.path)], text: '🌾 Crop Disease Detection History');
    return true;
  }
}
