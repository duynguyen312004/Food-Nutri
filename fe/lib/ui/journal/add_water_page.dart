import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddWaterPage extends StatefulWidget {
  const AddWaterPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddWaterPageState createState() => _AddWaterPageState();
}

class _AddWaterPageState extends State<AddWaterPage> {
  DateTime _selectedDateTime = DateTime.now();
  int _intakeMl = 250;

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
    // TODO: gọi LogService.addWater(_intakeMl, _selectedDateTime)
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm nước uống'),
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
            Row(
              children: [
                const Text('ML:'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _intakeMl.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _intakeMl = int.tryParse(v) ?? 0,
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
