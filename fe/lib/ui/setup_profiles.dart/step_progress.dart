// lib/ui/setup_profiles/step_progress.dart
import 'package:flutter/material.dart';

/// Represents a progress plan option with dynamic calculation
class ProgressOption {
  final String key;
  final String icon;
  final String difficulty;
  final int weeks;
  final double pace;
  final Color color;

  ProgressOption({
    required this.key,
    required this.icon,
    required this.difficulty,
    required this.weeks,
    required this.pace,
    required this.color,
  });
}

class ProgressStep extends StatelessWidget {
  final double? currentWeight;
  final double? targetWeight;
  final String? selectedPlan;
  final ValueChanged<String> onPlanSelected;

  const ProgressStep({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.selectedPlan,
    required this.onPlanSelected,
  });

  // Static definitions of pace, icons, labels
  static const Map<String, double> _paceMap = {
    'Thư giãn': 0.5,
    'Ổn định': 0.75,
    'Tăng cường': 1,
  };

  static const List<Map<String, dynamic>> _definitions = [
    {
      'key': 'Thư giãn',
      'icon': 'assets/icons/banana.png',
      'difficulty': 'Dễ',
      'color': Colors.green,
    },
    {
      'key': 'Ổn định',
      'icon': 'assets/icons/lift.png',
      'difficulty': 'Trung bình',
      'color': Colors.orange,
    },
    {
      'key': 'Tăng cường',
      'icon': 'assets/icons/cup.png',
      'difficulty': 'Khó',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // Compute difference
    final diff = (currentWeight != null && targetWeight != null)
        ? (currentWeight! - targetWeight!).abs()
        : 0.0;
    // Build dynamic options list
    final options = _definitions.map((def) {
      final key = def['key'] as String;
      final pace = _paceMap[key]!;
      final weeks = diff > 0 ? (diff / pace).ceil() : 0;
      return ProgressOption(
        key: key,
        icon: def['icon'] as String,
        difficulty: def['difficulty'] as String,
        weeks: weeks,
        pace: pace,
        color: def['color'] as Color,
      );
    }).toList();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.1), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn tiến trình',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn tốc độ thay đổi cân nặng phù hợp với mục tiêu của bạn',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          ...options.map((opt) {
            final isSelected = opt.key == selectedPlan;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => onPlanSelected(opt.key),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isSelected ? primary.withOpacity(0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? primary : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Row(
                    children: [
                      Image.asset(opt.icon, width: 28, height: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.key,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? primary : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: opt.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    opt.difficulty,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: opt.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${opt.weeks} Tuần • ${opt.pace}kg/tuần',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: primary, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
