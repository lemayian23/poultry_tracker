import 'package:hive/hive.dart';
import '../models/batch.dart';
import '../models/daily_record.dart';
import '../models/vaccination.dart';

class BatchService {
  static const String batchesBox = 'batches';
  static const String recordsBox = 'records';
  static const String vaccinationsBox = 'vaccinations';

  // Initialize Hive boxes - PUBLIC METHODS
  Future<Box<Batch>> openBatchesBox() async {
    if (!Hive.isBoxOpen(batchesBox)) {
      return await Hive.openBox<Batch>(batchesBox);
    }
    return Hive.box<Batch>(batchesBox);
  }

  Future<Box<DailyRecord>> openRecordsBox() async {
    if (!Hive.isBoxOpen(recordsBox)) {
      return await Hive.openBox<DailyRecord>(recordsBox);
    }
    return Hive.box<DailyRecord>(recordsBox);
  }

  Future<Box<Vaccination>> openVaccinationsBox() async {
    if (!Hive.isBoxOpen(vaccinationsBox)) {
      return await Hive.openBox<Vaccination>(vaccinationsBox);
    }
    return Hive.box<Vaccination>(vaccinationsBox);
  }

  // Batch operations
  Future<void> addBatch(Batch batch) async {
    final box = await openBatchesBox();
    await box.put(batch.id, batch);
  }

  Future<List<Batch>> getBatches() async {
    final box = await openBatchesBox();
    return box.values.toList();
  }

  Future<List<Batch>> getActiveBatches() async {
    final box = await openBatchesBox();
    return box.values.where((batch) => batch.isActive).toList();
  }

  Future<Batch?> getBatch(String batchId) async {
    final box = await openBatchesBox();
    return box.get(batchId);
  }

  Future<void> updateBatch(Batch batch) async {
    final box = await openBatchesBox();
    await box.put(batch.id, batch);
  }

  Future<void> deleteBatch(String batchId) async {
    final box = await openBatchesBox();
    await box.delete(batchId);
  }

  // Daily record operations
  Future<void> addDailyRecord(DailyRecord record) async {
    final box = await openRecordsBox();
    await box.put(record.id, record);
  }

  Future<List<DailyRecord>> getRecordsForBatch(String batchId) async {
    final box = await openRecordsBox();
    return box.values
        .where((record) => record.batchId == batchId)
        .toList();
  }

  Future<DailyRecord?> getRecordForDate(String batchId, DateTime date) async {
    final box = await openRecordsBox();
    final dateKey = _formatDateKey(date);
    
    final records = box.values.where((record) => 
      record.batchId == batchId && 
      _formatDateKey(record.date) == dateKey
    ).toList();
    
    return records.isNotEmpty ? records.first : null;
  }

  Future<void> updateDailyRecord(DailyRecord record) async {
    final box = await openRecordsBox();
    await box.put(record.id, record);
  }

  Future<void> deleteDailyRecord(String recordId) async {
    final box = await openRecordsBox();
    await box.delete(recordId);
  }

  // Helper method to format date as key
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  // Calculate total mortality for a batch
  Future<int> getTotalMortality(String batchId) async {
    final records = await getRecordsForBatch(batchId);
    int total = 0;
    for (final record in records) {
      total += record.mortality;
    }
    return total;
  }

  // Calculate total eggs for a batch
  Future<int> getTotalEggs(String batchId) async {
    final records = await getRecordsForBatch(batchId);
    int total = 0;
    for (final record in records) {
      total += record.eggsCollected;
    }
    return total;
  }

  // Calculate total feed consumed for a batch
  Future<double> getTotalFeed(String batchId) async {
    final records = await getRecordsForBatch(batchId);
    double total = 0;
    for (final record in records) {
      total += record.feedConsumed;
    }
    return total;
  }

  // Get today's record for a batch
  Future<DailyRecord?> getTodaysRecord(String batchId) async {
    return await getRecordForDate(batchId, DateTime.now());
  }

  // Vaccination operations
  Future<void> addVaccination(Vaccination vaccination) async {
    final box = await openVaccinationsBox();
    await box.put(vaccination.id, vaccination);
  }

  Future<List<Vaccination>> getVaccinationsForBatch(String batchId) async {
    final box = await openVaccinationsBox();
    return box.values
        .where((vaccination) => vaccination.batchId == batchId)
        .toList();
  }

  Future<List<Vaccination>> getDueVaccinations() async {
    final box = await openVaccinationsBox();
    final now = DateTime.now();
    return box.values
        .where((vaccination) => !vaccination.isCompleted && 
            (vaccination.isDueSoon || vaccination.isOverdue))
        .toList();
  }

  Future<List<Vaccination>> getUpcomingVaccinations() async {
    final box = await openVaccinationsBox();
    return box.values
        .where((vaccination) => !vaccination.isCompleted && 
            vaccination.nextDueDate.isAfter(DateTime.now()))
        .toList();
  }

  Future<void> updateVaccination(Vaccination vaccination) async {
    final box = await openVaccinationsBox();
    await box.put(vaccination.id, vaccination);
  }

  Future<void> deleteVaccination(String vaccinationId) async {
    final box = await openVaccinationsBox();
    await box.delete(vaccinationId);
  }

  // Analytics methods
  Future<Map<String, dynamic>> getBatchAnalytics(String batchId) async {
    final batch = await getBatch(batchId);
    if (batch == null) {
      throw Exception('Batch not found');
    }

    final totalMortality = await getTotalMortality(batchId);
    final totalEggs = await getTotalEggs(batchId);
    final totalFeed = await getTotalFeed(batchId);
    final vaccinations = await getVaccinationsForBatch(batchId);

    return {
      'batch': batch,
      'currentBirds': batch.getCurrentBirds(totalMortality),
      'totalMortality': totalMortality,
      'totalEggs': totalEggs,
      'totalFeed': totalFeed,
      'vaccinationCount': vaccinations.length,
      'completedVaccinations': vaccinations.where((v) => v.isCompleted).length,
      'pendingVaccinations': vaccinations.where((v) => !v.isCompleted).length,
    };
  }

  // Get farm-wide statistics
  Future<Map<String, dynamic>> getFarmStatistics() async {
    final batches = await getActiveBatches();
    int totalBirds = 0;
    int totalMortality = 0;
    int totalEggs = 0;
    double totalFeed = 0;

    for (final batch in batches) {
      final batchMortality = await getTotalMortality(batch.id);
      final batchEggs = await getTotalEggs(batch.id);
      final batchFeed = await getTotalFeed(batch.id);
      
      totalBirds += batch.getCurrentBirds(batchMortality);
      totalMortality += batchMortality;
      totalEggs += batchEggs;
      totalFeed += batchFeed;
    }

    return {
      'totalBatches': batches.length,
      'totalBirds': totalBirds,
      'totalMortality': totalMortality,
      'totalEggs': totalEggs,
      'totalFeed': totalFeed,
      'averageBirdsPerBatch': batches.isNotEmpty ? totalBirds / batches.length : 0,
    };
  }
}