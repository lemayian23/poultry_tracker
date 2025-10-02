class ExportService {
  String generateExportSummary(int batchCount, int totalBirds, int totalEggs) {
    return '''
POULTRY FARM REPORT
===================

Total Batches: $batchCount
Total Birds Alive: $totalBirds
Total Eggs Collected: $totalEggs

Generated on: ${DateTime.now()}
''';
  }
}