// lib/ui/setup_profiles/step_goal.dart
import 'package:flutter/material.dart';

class GoalStep extends StatelessWidget {
  final String? selectedGoal;
  final ValueChanged<String> onGoalSelected;

  const GoalStep({
    super.key,
    required this.selectedGoal,
    required this.onGoalSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final options = [
      {'key': 'Giảm cân', 'icon': 'assets/icons/banana.png'},
      {'key': 'Tăng cân', 'icon': 'assets/icons/lift.png'},
      {'key': 'Giữ nguyên', 'icon': 'assets/icons/cup.png'},
    ];

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
            'Mục tiêu của bạn?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cá nhân hóa trải nghiệm FoodNutri của bạn bằng cách tạo tài khoản',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          ...options.map((opt) {
            final key = opt['key']!;
            final iconPath = opt['icon']!;
            final isSelected = key == selectedGoal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => onGoalSelected(key),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? primary.withOpacity(0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? primary : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(iconPath, width: 28, height: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? primary : Colors.black87,
                          ),
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
