import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/batch.dart';
import '../models/daily_record.dart';
import '../services/batch_service.dart';
import 'vaccination_screen.dart';

class BatchDetailScreen extends StatefulWidget {
  final Batch batch;

  const BatchDetailScreen({super.key, required this.batch});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  final BatchService _batchService = BatchService();
  final Uuid _uuid = const Uuid();
  
  DateTime _selectedDate = DateTime.now();
  DailyRecord? _todayRecord;
  int _currentBirds = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await _loadTodayRecord();
      await _loadCurrentBirds();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading batch details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTodayRecord() async {
    final record = await _batchService.getRecordForDate(widget.batch.id, _selectedDate);
    setState(() {
      _todayRecord = record;
    });
  }

  Future<void> _loadCurrentBirds() async {
    final totalMortality = await _batchService.getTotalMortality(widget.batch.id);
    setState(() {
      _currentBirds = widget.batch.getCurrentBirds(totalMortality);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.batch.startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      await _loadTodayRecord();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMortality(int change) {
    setState(() {
      if (_todayRecord == null) {
        _todayRecord = DailyRecord(
          id: _uuid.v4(),
          batchId: widget.batch.id,
          date: _selectedDate,
          mortality: change > 0 ? 1 : 0,
        );
      } else {
        _todayRecord!.mortality = (_todayRecord!.mortality + change).clamp(0, _currentBirds);
      }
    });
    _saveRecord();
  }

  void _updateEggs(int change) {
    setState(() {
      if (_todayRecord == null) {
        _todayRecord = DailyRecord(
          id: _uuid.v4(),
          batchId: widget.batch.id,
          date: _selectedDate,
          eggsCollected: change > 0 ? 1 : 0,
        );
      } else {
        _todayRecord!.eggsCollected = (_todayRecord!.eggsCollected + change).clamp(0, 10000);
      }
    });
    _saveRecord();
  }

  void _updateFeed(double change) {
    setState(() {
      if (_todayRecord == null) {
        _todayRecord = DailyRecord(
          id: _uuid.v4(),
          batchId: widget.batch.id,
          date: _selectedDate,
          feedConsumed: change > 0 ? 0.5 : 0,
        );
      } else {
        _todayRecord!.feedConsumed = (_todayRecord!.feedConsumed + change).clamp(0, 1000);
      }
    });
    _saveRecord();
  }

  Future<void> _saveRecord() async {
    if (_todayRecord != null) {
      try {
        if (_todayRecord!.mortality == 0 && 
            _todayRecord!.eggsCollected == 0 && 
            _todayRecord!.feedConsumed == 0) {
          // Don't save empty records
          return;
        }
        
        await _batchService.addDailyRecord(_todayRecord!);
        await _loadCurrentBirds(); // Refresh bird count after mortality changes
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRecordDetails() {
    if (_todayRecord == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${DateFormat('MMMM d, yyyy').format(_selectedDate)}'),
            const SizedBox(height: 8),
            Text('Mortality: ${_todayRecord!.mortality} birds'),
            Text('Eggs Collected: ${_todayRecord!.eggsCollected}'),
            Text('Feed Consumed: ${_todayRecord!.feedConsumed} kg'),
            if (_todayRecord!.notes != null && _todayRecord!.notes!.isNotEmpty)
              Text('Notes: ${_todayRecord!.notes}'),
          ],
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batch.name),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VaccinationScreen(batch: widget.batch),
                ),
              );
            },
            tooltip: 'Vaccinations',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showRecordDetails,
            tooltip: 'Record Details',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Batch Summary Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batch Summary',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryItem('Initial Birds', '${widget.batch.initialBirds}'),
                              _buildSummaryItem('Current Birds', '$_currentBirds'),
                              _buildSummaryItem('Age', '${widget.batch.ageInDays} days'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryItem('Type', _formatBatchType(widget.batch.type)),
                              _buildSummaryItem('Status', widget.batch.isActive ? 'Active' : 'Inactive'),
                              _buildSummaryItem('Start Date', _formatDate(widget.batch.startDate)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Date Selector
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.arrow_drop_down, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Daily Records Section
                  Text(
                    'Daily Records',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Mortality Tracker
                  _buildTrackerCard(
                    title: 'Mortality',
                    value: _todayRecord?.mortality ?? 0,
                    unit: 'birds',
                    color: Colors.red,
                    onIncrement: () => _updateMortality(1),
                    onDecrement: () => _updateMortality(-1),
                    icon: Icons.flag,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Egg Production
                  _buildTrackerCard(
                    title: 'Eggs Collected',
                    value: _todayRecord?.eggsCollected ?? 0,
                    unit: 'eggs',
                    color: Colors.amber,
                    onIncrement: () => _updateEggs(1),
                    onDecrement: () => _updateEggs(-1),
                    icon: Icons.egg,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Feed Consumption
                  _buildTrackerCard(
                    title: 'Feed Consumed',
                    value: _todayRecord?.feedConsumed ?? 0,
                    unit: 'kg',
                    color: Colors.blue,
                    onIncrement: () => _updateFeed(0.5),
                    onDecrement: () => _updateFeed(-0.5),
                    icon: Icons.restaurant,
                    isDecimal: true,
                  ),

                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.medical_services, size: 16),
                                label: const Text('Vaccinations'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VaccinationScreen(batch: widget.batch),
                                    ),
                                  );
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.analytics, size: 16),
                                label: const Text('View History'),
                                onPressed: () {
                                  // TODO: Navigate to records history screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Records history coming soon!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackerCard({
    required String title,
    required dynamic value,
    required String unit,
    required Color color,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required IconData icon,
    bool isDecimal = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  onPressed: onDecrement,
                  mini: true,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.remove, color: Colors.white),
                  heroTag: '${title}_decrement', // Unique hero tag
                ),
                Column(
                  children: [
                    Text(
                      isDecimal ? (value as double).toStringAsFixed(1) : value.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                FloatingActionButton(
                  onPressed: onIncrement,
                  mini: true,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add, color: Colors.white),
                  heroTag: '${title}_increment', // Unique hero tag
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBatchType(String type) {
    switch (type) {
      case 'broiler':
        return 'Broiler';
      case 'layer':
        return 'Layer';
      case 'kienyeji':
        return 'Kienyeji';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}