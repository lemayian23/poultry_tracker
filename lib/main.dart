import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poultry Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'Egg Counter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  DateTime _selectedDate = DateTime.now(); 
  Map<String, int> _eggRecords = {};

  void _incrementCounter() {
    setState(() {
      _counter++;
      _saveEggCount();
    });
  }

  void _decrementCounter() {
      setState(() {
        if (_counter > 0) {
          _counter--;
          _saveEggCount();
        }
      });
    }
Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2026, 12, 31),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _counter = _getEggCountForDate(picked);
      });
    }
  }
  String _formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  int _getEggCountForDate(DateTime date) {
    String key = _formatDateKey(date);
    return _eggRecords[key] ?? 0;
  }

  void _saveEggCount() {
    String key = _formatDateKey(_selectedDate);
    _eggRecords[key] = _counter;
  }
  void _showHistory() {
    // Calculate total eggs
    int totalEggs = _eggRecords.values.fold(0, (sum, count) => sum + count);
    
    // Sort records by date (newest first)
    List<MapEntry<String, int>> sortedRecords = _eggRecords.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Egg Collection History'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Total summary
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Eggs:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$totalEggs 🥚',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(),
                // Records list
                Expanded(
                  child: sortedRecords.isEmpty
                      ? const Center(
                          child: Text('No records yet. Start collecting!'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: sortedRecords.length,
                          itemBuilder: (context, index) {
                            String dateKey = sortedRecords[index].key;
                            int eggCount = sortedRecords[index].value;
                            DateTime date = DateTime.parse(dateKey);
                            
                            return ListTile(
                              leading: const Icon(
                                Icons.calendar_today,
                                color: Colors.green,
                              ),
                              title: Text(
                                DateFormat('EEEE, MMM d, yyyy').format(date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Text(
                                '$eggCount eggs',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ADDED DATE DISPLAY
                        GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Eggs collected:',  // CHANGED from "today"
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
        floatingActionButton: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      FloatingActionButton(
        onPressed: _showHistory,
        tooltip: 'View History',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.history),
      ),
      const SizedBox(width: 10),
      FloatingActionButton(
        onPressed: _decrementCounter,
        tooltip: 'Remove egg',
        backgroundColor: Colors.red,
        child: const Icon(Icons.remove),
      ),
      const SizedBox(width: 10),
      FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Add egg',
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    ],
  ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}