import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddExercisePageState createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  DateTime _selectedDateTime = DateTime.now();
  int _durationMin = 30;
  final int _selectedTypeId = 20; // id exercise_type mặc định

  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    // TODO: gọi LogService.addExercise(_selectedTypeId, _durationMin, _selectedDateTime)
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm bài tập'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime)),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),
            // TODO: dropdown chọn exercise type từ DB
            Row(
              children: [
                const Text('Thời lượng (phút):'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _durationMin.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _durationMin = int.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(onPressed: _submit, child: const Text('Lưu')),
          ],
        ),
      ),
    );
  }
}
