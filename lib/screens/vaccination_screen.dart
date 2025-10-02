import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/batch.dart';
import '../models/vaccination.dart';
import '../services/batch_service.dart';

class VaccinationScreen extends StatefulWidget {
  final Batch batch;

  const VaccinationScreen({super.key, required this.batch});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  final BatchService _batchService = BatchService();
  final Uuid _uuid = const Uuid();
  List<Vaccination> _vaccinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVaccinations();
  }

  Future<void> _loadVaccinations() async {
    try {
      final vaccinations = await _batchService.getVaccinationsForBatch(widget.batch.id);
      setState(() {
        _vaccinations = vaccinations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading vaccinations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddVaccinationDialog() {
    showDialog(
      context: context,
      builder: (context) => AddVaccinationDialog(
        batchId: widget.batch.id,
        onVaccinationAdded: _loadVaccinations,
      ),
    );
  }

  void _markAsCompleted(Vaccination vaccination) async {
    try {
      final updatedVaccination = Vaccination(
        id: vaccination.id,
        batchId: vaccination.batchId,
        vaccineName: vaccination.vaccineName,
        dateGiven: vaccination.dateGiven,
        nextDueDate: vaccination.nextDueDate,
        notes: vaccination.notes,
        isCompleted: true,
        administeredBy: vaccination.administeredBy,
        dosage: vaccination.dosage,
        administrationRoute: vaccination.administrationRoute,
        manufacturer: vaccination.manufacturer,
        batchNumber: vaccination.batchNumber,
      );

      await _batchService.updateVaccination(updatedVaccination);
      await _loadVaccinations();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaccination marked as completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating vaccination: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteVaccination(Vaccination vaccination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vaccination'),
        content: Text('Are you sure you want to delete "${vaccination.vaccineName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _batchService.deleteVaccination(vaccination.id);
        await _loadVaccinations();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vaccination deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting vaccination: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vaccinations - ${widget.batch.name}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Due Vaccinations Alert
          FutureBuilder<List<Vaccination>>(
            future: _batchService.getDueVaccinations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox();
              }
              
              final dueVaccinations = snapshot.data?.where((v) => v.batchId == widget.batch.id).toList() ?? [];
              
              if (dueVaccinations.isEmpty) return const SizedBox();
              
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vaccination Due',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            '${dueVaccinations.length} vaccination${dueVaccinations.length != 1 ? 's' : ''} due soon',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _vaccinations.isEmpty
                    ? _buildEmptyState()
                    : _buildVaccinationsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVaccinationDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        heroTag: 'vaccination_fab',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'No Vaccinations',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add vaccination schedule for this batch',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationsList() {
    return RefreshIndicator(
      onRefresh: _loadVaccinations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vaccinations.length,
        itemBuilder: (context, index) {
          final vaccination = _vaccinations[index];
          return _buildVaccinationCard(vaccination);
        },
      ),
    );
  }

  Widget _buildVaccinationCard(Vaccination vaccination) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getVaccinationColor(vaccination).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.medical_services,
            color: _getVaccinationColor(vaccination),
          ),
        ),
        title: Text(
          vaccination.vaccineName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: vaccination.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Given: ${_formatDate(vaccination.dateGiven)}'),
            Text('Next Due: ${_formatDate(vaccination.nextDueDate)}'),
            if (vaccination.dosage != null) Text('Dosage: ${vaccination.dosage} ml'),
            if (vaccination.administrationRoute != null) Text('Route: ${vaccination.administrationRoute}'),
            if (vaccination.notes != null && vaccination.notes!.isNotEmpty) 
              Text('Notes: ${vaccination.notes}'),
            const SizedBox(height: 4),
            if (vaccination.isDueSoon && !vaccination.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Due in ${vaccination.daysFromDue.abs()} days',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (vaccination.isOverdue && !vaccination.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Overdue by ${vaccination.daysFromDue.abs()} days',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!vaccination.isCompleted)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _markAsCompleted(vaccination),
                tooltip: 'Mark as completed',
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteVaccination(vaccination),
              tooltip: 'Delete vaccination',
            ),
          ],
        ),
        onLongPress: () => _showVaccinationDetails(vaccination),
      ),
    );
  }

  void _showVaccinationDetails(Vaccination vaccination) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vaccination.vaccineName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status:', vaccination.status),
              _buildDetailRow('Date Given:', _formatDate(vaccination.dateGiven)),
              _buildDetailRow('Next Due:', _formatDate(vaccination.nextDueDate)),
              _buildDetailRow('Due Status:', vaccination.dueStatus),
              if (vaccination.dosage != null) _buildDetailRow('Dosage:', '${vaccination.dosage} ml'),
              if (vaccination.administrationRoute != null) _buildDetailRow('Route:', vaccination.administrationRoute!),
              if (vaccination.manufacturer != null) _buildDetailRow('Manufacturer:', vaccination.manufacturer!),
              if (vaccination.batchNumber != null) _buildDetailRow('Batch No:', vaccination.batchNumber!),
              if (vaccination.administeredBy != null) _buildDetailRow('Administered By:', vaccination.administeredBy!),
              if (vaccination.notes != null && vaccination.notes!.isNotEmpty) 
                _buildDetailRow('Notes:', vaccination.notes!),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getVaccinationColor(Vaccination vaccination) {
    if (vaccination.isCompleted) return Colors.green;
    if (vaccination.isOverdue) return Colors.red;
    if (vaccination.isDueSoon) return Colors.orange;
    return Colors.blue;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class AddVaccinationDialog extends StatefulWidget {
  final String batchId;
  final VoidCallback onVaccinationAdded;

  const AddVaccinationDialog({
    super.key,
    required this.batchId,
    required this.onVaccinationAdded,
  });

  @override
  State<AddVaccinationDialog> createState() => _AddVaccinationDialogState();
}

class _AddVaccinationDialogState extends State<AddVaccinationDialog> {
  final _formKey = GlobalKey<FormState>();
  final BatchService _batchService = BatchService();
  final Uuid _uuid = const Uuid();

  final List<String> _commonVaccines = VaccineConstants.commonVaccines;
  final List<String> _administrationRoutes = VaccineConstants.administrationRoutes;

  String _vaccineName = '';
  DateTime _dateGiven = DateTime.now();
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 30));
  String? _notes;
  String? _administeredBy;
  double? _dosage;
  String? _administrationRoute;
  String? _manufacturer;
  String? _batchNumber;

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? _nextDueDate : _dateGiven,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _nextDueDate = picked;
        } else {
          _dateGiven = picked;
        }
      });
    }
  }

  void _saveVaccination() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newVaccination = Vaccination(
        id: _uuid.v4(),
        batchId: widget.batchId,
        vaccineName: _vaccineName,
        dateGiven: _dateGiven,
        nextDueDate: _nextDueDate,
        notes: _notes?.isEmpty ?? true ? null : _notes,
        administeredBy: _administeredBy?.isEmpty ?? true ? null : _administeredBy,
        dosage: _dosage,
        administrationRoute: _administrationRoute?.isEmpty ?? true ? null : _administrationRoute,
        manufacturer: _manufacturer?.isEmpty ?? true ? null : _manufacturer,
        batchNumber: _batchNumber?.isEmpty ?? true ? null : _batchNumber,
      );

      // Validate dates
      if (_nextDueDate.isBefore(_dateGiven)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Next due date cannot be before date given'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        await _batchService.addVaccination(newVaccination);
        widget.onVaccinationAdded();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vaccination added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving vaccination: $e'),
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
      title: const Text('Add Vaccination'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _vaccineName.isEmpty ? null : _vaccineName,
                decoration: const InputDecoration(
                  labelText: 'Vaccine Name *',
                  border: OutlineInputBorder(),
                ),
                items: _commonVaccines.map((String vaccine) {
                  return DropdownMenuItem<String>(
                    value: vaccine,
                    child: Text(vaccine),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _vaccineName = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a vaccine';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context, false),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Date Given *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: '${_dateGiven.day}/${_dateGiven.month}/${_dateGiven.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context, true),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Next Due Date *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: '${_nextDueDate.day}/${_nextDueDate.month}/${_nextDueDate.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Dosage (ml)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 0.5',
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _dosage = value?.isEmpty ?? true ? null : double.tryParse(value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _administrationRoute,
                decoration: const InputDecoration(
                  labelText: 'Administration Route',
                  border: OutlineInputBorder(),
                ),
                items: _administrationRoutes.map((String route) {
                  return DropdownMenuItem<String>(
                    value: route,
                    child: Text(route),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _administrationRoute = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Administered By',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Dr. John',
                ),
                onSaved: (value) => _administeredBy = value?.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes',
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
          onPressed: _saveVaccination,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Vaccination'),
        ),
      ],
    );
  }
}