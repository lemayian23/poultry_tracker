import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/batch.dart';
import '../services/batch_service.dart';
import 'batch_detail_screen.dart';

class BatchListScreen extends StatefulWidget {
  const BatchListScreen({super.key});

  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> {
  final BatchService _batchService = BatchService();
  List<Batch> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    try {
      final batches = await _batchService.getActiveBatches();
      setState(() {
        _batches = batches;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading batches: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Poultry Batches'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _batches.isEmpty
              ? _buildEmptyState()
              : _buildBatchesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBatchDialog(context);
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        heroTag: 'batch_list_fab',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.agriculture,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No batches yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Start by adding your first batch of chickens',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _showAddBatchDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Add First Batch'),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesList() {
    return RefreshIndicator(
      onRefresh: _loadBatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _batches.length,
        itemBuilder: (context, index) {
          final batch = _batches[index];
          return _buildBatchCard(batch);
        },
      ),
    );
  }

  Widget _buildBatchCard(Batch batch) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _getBatchIcon(batch.type),
        title: Text(
          batch.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: FutureBuilder<int>(
          future: _batchService.getTotalMortality(batch.id),
          builder: (context, snapshot) {
            final mortality = snapshot.data ?? 0;
            final currentBirds = batch.getCurrentBirds(mortality);
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Type: ${_formatBatchType(batch.type)}'),
                Text('Age: ${batch.ageInDays} days'),
                Text('Birds: $currentBirds/${batch.initialBirds} alive'),
                Text('Started: ${_formatDate(batch.startDate)}'),
              ],
            );
          },
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BatchDetailScreen(batch: batch),
            ),
          ).then((_) => _loadBatches()); // Refresh when returning
        },
      ),
    );
  }

  Widget _getBatchIcon(String type) {
    Color color;
    IconData icon;
    
    switch (type) {
      case 'broiler':
        color = Colors.orange;
        icon = Icons.emoji_people;
        break;
      case 'layer':
        color = Colors.yellow[700]!;
        icon = Icons.egg;
        break;
      case 'kienyeji':
        color = Colors.brown;
        icon = Icons.agriculture;
        break;
      default:
        color = Colors.green;
        icon = Icons.pets;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
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

  void _showAddBatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddBatchDialog(
        onBatchAdded: () {
          _loadBatches(); // Reload the list
        },
      ),
    );
  }
}

class AddBatchDialog extends StatefulWidget {
  final VoidCallback onBatchAdded;

  const AddBatchDialog({super.key, required this.onBatchAdded});

  @override
  State<AddBatchDialog> createState() => _AddBatchDialogState();
}

class _AddBatchDialogState extends State<AddBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final BatchService _batchService = BatchService();
  final Uuid _uuid = const Uuid();

  String _name = '';
  DateTime _startDate = DateTime.now();
  int _initialBirds = 0;
  String _type = 'layer';
  String? _notes;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _saveBatch() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newBatch = Batch(
        id: _uuid.v4(),
        name: _name,
        startDate: _startDate,
        initialBirds: _initialBirds,
        type: _type,
        notes: _notes?.isEmpty ?? true ? null : _notes,
      );

      try {
        await _batchService.addBatch(newBatch);
        widget.onBatchAdded();
        if (mounted) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Batch added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving batch: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Batch'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Batch Name',
                  hintText: 'e.g., Layer Batch 1',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a batch name';
                  }
                  if (value.length < 2) {
                    return 'Batch name too short';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!.trim(),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Number of Birds',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 100',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of birds';
                  }
                  final birds = int.tryParse(value);
                  if (birds == null || birds <= 0) {
                    return 'Please enter a valid number (1-100000)';
                  }
                  if (birds > 100000) {
                    return 'Maximum 100,000 birds allowed';
                  }
                  return null;
                },
                onSaved: (value) => _initialBirds = int.parse(value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Bird Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'layer', child: Text('Layers 🥚')),
                  DropdownMenuItem(value: 'broiler', child: Text('Broilers 🍗')),
                  DropdownMenuItem(value: 'kienyeji', child: Text('Kienyeji 🐔')),
                ],
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Any additional information...',
                ),
                maxLines: 2,
                onSaved: (value) => _notes = value?.trim(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveBatch,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Batch'),
        ),
      ],
    );
  }
}