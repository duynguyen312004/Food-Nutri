import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeightHistoryPage extends StatelessWidget {
  final List logs;
  const WeightHistoryPage({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Lịch sử cân nặng',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Colors.white12, height: 1),
        itemBuilder: (context, idx) {
          final entry = logs[idx];
          return ListTile(
            title: Text(
              DateFormat('dd/MM/yyyy').format(entry.loggedAt),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            trailing: Text(
              '${entry.weightKg.toStringAsFixed(1)} kg',
              style: const TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
