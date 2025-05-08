// lib/ui/setup_profiles/step_dob.dart (refined)
import 'package:flutter/material.dart';

class DobStep extends StatelessWidget {
  final DateTime? selectedDob;
  final ValueChanged<DateTime> onDobSelected;

  const DobStep({
    super.key,
    required this.selectedDob,
    required this.onDobSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
            'Ngày sinh của bạn?',
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
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDob ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) onDobSelected(date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDob != null
                          ? '${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}'
                          : 'Sinh nhật',
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedDob != null
                            ? Colors.black87
                            : Colors.grey[500],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: primary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
