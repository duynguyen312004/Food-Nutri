import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/exercise/exercise_cubit.dart';
import '../../blocs/exercise/exercise_state.dart';

class AddExercisePage extends StatefulWidget {
  final DateTime selectedDate;
  final int selectedHour;

  const AddExercisePage({
    super.key,
    required this.selectedDate,
    required this.selectedHour,
  });

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final int _durationMin = 30;

  DateTime get _timestamp => DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        widget.selectedHour,
      );

  void _showDurationInput(int typeId, String typeName) {
    final controller = TextEditingController(text: _durationMin.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tập "$typeName"',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian tập (phút)',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final val = int.tryParse(controller.text);
                      if (val != null && val > 0) {
                        Navigator.pop(
                            context, {'typeId': typeId, 'duration': val});
                      }
                    },
                    child: const Text('Lưu'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((result) {
      if (result != null && mounted) {
        Navigator.pop(context, {
          'typeId': result['typeId'],
          'duration': result['duration'],
          'timestamp': _timestamp,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeRange =
        '${widget.selectedHour.toString().padLeft(2, '0')}:00 - ${(widget.selectedHour + 1).toString().padLeft(2, '0')}:00 | ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm bài tập'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                timeRange,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ExerciseCubit, ExerciseState>(
              builder: (context, state) {
                if (state is ExerciseTypesLoaded) {
                  final types = state.types;

                  return ListView.builder(
                    itemCount: types.length,
                    itemBuilder: (context, index) {
                      final type = types[index];
                      return ListTile(
                        title: Text(type.name,
                            style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: Colors.white54, size: 16),
                        onTap: () => _showDurationInput(type.id, type.name),
                      );
                    },
                  );
                } else if (state is ExerciseLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ExerciseError) {
                  return Center(
                      child: Text('Lỗi: ${state.message}',
                          style: const TextStyle(color: Colors.red)));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
