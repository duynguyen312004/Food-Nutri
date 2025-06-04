import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:nutrition_app/ui/journal/add_exercise_page.dart';
import 'package:nutrition_app/ui/journal/add_meal_page.dart';
import 'package:nutrition_app/utils/dialog_helper.dart';

import '../../blocs/log/journal_cubit.dart';
import '../../blocs/metrics/metrics_cubit.dart';

class AddEntryPage extends StatefulWidget {
  final DateTime selectedDate;
  final int selectedHour;

  const AddEntryPage({
    super.key,
    required this.selectedDate,
    required this.selectedHour,
  });

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          '${widget.selectedHour.toString().padLeft(2, '0')}:00'
          ' - ${(widget.selectedHour + 1).toString().padLeft(2, '0')}:00',
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const SizedBox(height: 8),

          // Thêm bữa ăn
          _OptionTile(
            icon: Icons.fastfood,
            label: 'Thêm bữa ăn',
            color: Colors.orangeAccent,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMealPage(
                    selectedDate: widget.selectedDate,
                    selectedHour: widget.selectedHour,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Thêm nước uống
          _OptionTile(
            icon: Icons.local_drink,
            label: 'Thêm nước uống',
            color: Colors.lightBlueAccent,
            onTap: () => showAddWaterSheet(
              context: context,
              selectedDate: widget.selectedDate,
              selectedHour: widget.selectedHour,
            ),
          ),
          const SizedBox(height: 16),

          // Thêm bài tập
          _OptionTile(
            icon: Icons.fitness_center,
            label: 'Thêm bài tập',
            color: Colors.redAccent,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExercisePage(
                    selectedDate: widget.selectedDate,
                    selectedHour: widget.selectedHour,
                  ),
                ),
              );

              if (result != null && result is Map) {
                final int typeId = result['typeId'] as int;
                final int duration = result['duration'] as int;
                final DateTime timestamp = result['timestamp'] as DateTime;

                if (!context.mounted) return;
                await context.read<JournalCubit>().addExerciseLog(
                      timestamp,
                      exerciseTypeId: typeId,
                      durationMin: duration,
                    );
                if (!context.mounted) return;

                context.read<MetricsCubit>().loadMetricsForDate(timestamp);
                showSuccessDialog(context, 'Đã thêm bài tập thành công!');
              }
            },
          ),
          const SizedBox(height: 40),

          // Animation + slogan
          Center(
            child: Column(
              children: [
                Lottie.asset(
                  'assets/lottie/thinking_woman.json',
                  height: 250,
                  repeat: true,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Theo dõi từng bước nhỏ mỗi ngày!',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Tách hàm showAddWaterSheet ra ngoài cho dễ bảo trì/tái sử dụng
Future<void> showAddWaterSheet({
  required BuildContext context,
  required DateTime selectedDate,
  required int selectedHour,
}) async {
  int ml = 0;

  await showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2C2C3A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Thêm nước uống',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Image.asset('assets/icons/water.png', width: 40),
                    const SizedBox(width: 12),
                    Text(
                      '$ml ml',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.grey),
                      onPressed: () {
                        if (ml >= 180) setState(() => ml -= 180);
                      },
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.add, color: Colors.lightBlueAccent),
                      onPressed: () => setState(() => ml += 180),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ml > 0
                        ? () async {
                            final timestamp = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedHour,
                            );
                            try {
                              await context
                                  .read<JournalCubit>()
                                  .addWaterLog(timestamp, ml);
                              if (!context.mounted) return;
                              await showSuccessDialog(
                                  context, 'Đã thêm $ml ml nước');
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  if (context.mounted) {
                                    showSuccessDialog(
                                        context, 'Đã thêm $ml ml nước');
                                  }
                                });
                              }
                            }
                          }
                        : null,
                    child: const Text('Lưu'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// Widget option tile tái sử dụng
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2C2C3A),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          radius: 24,
          child: Icon(icon, color: color),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white60, size: 18),
        onTap: onTap,
      ),
    );
  }
}
