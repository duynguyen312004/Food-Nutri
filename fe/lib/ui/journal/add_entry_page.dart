import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:nutrition_app/ui/journal/add_exercise_page.dart';
import 'package:nutrition_app/ui/journal/add_meal_page.dart';

import '../../blocs/log/journal_cubit.dart';

class AddEntryPage extends StatelessWidget {
  final DateTime selectedDate;
  final int selectedHour;

  const AddEntryPage({
    super.key,
    required this.selectedDate,
    required this.selectedHour,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('${selectedHour.toString().padLeft(2, '0')}:00'
            ' - ${(selectedHour + 1).toString().padLeft(2, '0')}:00'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.fastfood,
            label: 'Thêm bữa ăn',
            color: Colors.orangeAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddMealPage(
                  selectedDate: selectedDate,
                  selectedHour: selectedHour,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _OptionTile(
            icon: Icons.local_drink,
            label: 'Thêm nước uống',
            color: Colors.lightBlueAccent,
            onTap: () => _showAddWaterSheet(context),
          ),
          const SizedBox(height: 16),
          _OptionTile(
            icon: Icons.fitness_center,
            label: 'Thêm bài tập',
            color: Colors.redAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExercisePage()),
            ),
          ),
          const SizedBox(height: 40),
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

  void _showAddWaterSheet(BuildContext context) async {
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
                        icon: const Icon(Icons.add,
                            color: Colors.lightBlueAccent),
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
                                // Gọi Cubit để thêm nước
                                await context
                                    .read<JournalCubit>()
                                    .addWaterLog(timestamp, ml);
                                if (!context.mounted) return;
                                Navigator.pop(context); // đóng popup
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text('Đã thêm $ml ml nước'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi khi thêm nước: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
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
}

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
