import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/log/weight_log_cubit.dart';
import '../../blocs/log/weight_log_state.dart';
import '../../models/goal_model.dart';

/// Trang đặt/hiển thị mục tiêu cá nhân
class GoalPage extends StatelessWidget {
  final double? startingWeight;
  final double? targetWeight;
  final GoalModel goal;

  const GoalPage({
    super.key,
    required this.startingWeight,
    required this.targetWeight,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mục tiêu',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: BlocBuilder<WeightLogCubit, WeightLogState>(
        builder: (context, weightState) {
          double? currentWeight;
          if (weightState is WeightLogLoaded && weightState.logs.isNotEmpty) {
            // Lấy log mới nhất (đã sort DESC)
            currentWeight = weightState.logs.first.weightKg;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Cân nặng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildGoalItem(
                'Mục tiêu của bạn',
                goal.goalDirection.isNotEmpty
                    ? _mapGoalDirection(goal.goalDirection)
                    : '--',
              ),
              const Divider(color: Colors.white12),
              _buildGoalItem(
                'Cân nặng bắt đầu',
                startingWeight != null
                    ? '${startingWeight!.toStringAsFixed(1)} Kg'
                    : '-- Kg',
              ),
              const Divider(color: Colors.white12),
              _buildGoalItem(
                'Cân nặng mục tiêu',
                targetWeight != null
                    ? '${targetWeight!.toStringAsFixed(1)} Kg'
                    : '-- Kg',
              ),
              const Divider(color: Colors.white12),
              _buildGoalItem(
                'Cân nặng hiện tại',
                currentWeight != null
                    ? '${currentWeight.toStringAsFixed(1)} Kg'
                    : '-- Kg',
              ),
              const Divider(color: Colors.white12),
              _buildGoalItem(
                'Mục tiêu hàng tuần',
                '${goal.goalDirection == "giảm cân" ? "Giảm" : "Tăng"} '
                    '${goal.weeklyRate.toStringAsFixed(2)} Kg/tuần',
              ),
              const SizedBox(height: 24),
              // Mục tiêu dinh dưỡng (placeholder)
              const Text(
                'Mục tiêu dinh dưỡng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildClickableItem(
                context,
                title: 'Mục tiêu calo & macro',
                subtitle: 'Tùy chỉnh mục tiêu hàng ngày của bạn',
                onTap: () {},
              ),
              const Divider(color: Colors.white12),
              _buildClickableItem(
                context,
                title: 'Chế độ ăn',
                subtitle: '',
                onTap: () {},
              ),
              const Divider(color: Colors.white12),
              _buildDisabledItem(
                title: 'Thực phẩm loại trừ',
                subtitle: 'Loại bỏ các thực phẩm bạn dị ứng hoặc không thích',
              ),
              const SizedBox(height: 24),
              // Phần nước uống (nếu có)
              const Text(
                'Nước',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildGoalItem('Mục tiêu', '2000 mL'),
              const Divider(color: Colors.white12),
              _buildGoalItem('Dung tích mỗi lần ghi lại', '180 mL'),
              const SizedBox(height: 40),
              // Có thể thêm nút lưu hoặc giải thích nếu cần
            ],
          );
        },
      ),
    );
  }

  /// Helper hiển thị 1 item mục tiêu (label + value)
  Widget _buildGoalItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              child: Text(label,
                  style: const TextStyle(color: Colors.white60, fontSize: 16))),
          const SizedBox(width: 16),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Helper cho item bấm được
  Widget _buildClickableItem(BuildContext context,
      {required String title, String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: subtitle != null && subtitle.isNotEmpty
          ? Text(subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 14))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }

  /// Helper cho item bị disable (không bấm được)
  Widget _buildDisabledItem({required String title, String? subtitle}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(color: Colors.white54, fontSize: 16)),
      subtitle: subtitle != null && subtitle.isNotEmpty
          ? Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 13))
          : null,
      enabled: false,
    );
  }

  /// Map text cho goalDirection
  String _mapGoalDirection(String dir) {
    if (dir == 'giảm cân') return 'Giảm cân';
    if (dir == 'tăng cân') return 'Tăng cân';
    return dir;
  }
}
