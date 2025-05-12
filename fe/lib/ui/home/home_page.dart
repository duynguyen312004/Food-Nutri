import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../blocs/metrics/metrics_state.dart';
import '../../blocs/recent_log/recent_log_cubit.dart';
import '../../blocs/recent_log/recent_log_state.dart';

/// HomePage gồm Header, Calorie Card và Macro Pager với dữ liệu động từ MetricsCubit
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedWeekday = DateTime.now().weekday % 7; // 0: CN ... 6: T7

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    context.read<MetricsCubit>().loadMetricsForDate(today);
    context.read<RecentLogsCubit>().loadRecentLogs(today);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MetricsCubit, MetricsState>(
          builder: (context, state) {
            if (state is MetricsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MetricsError) {
              return Center(child: Text(state.message));
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                    child: _buildCalorieCard(state as MetricsLoaded)),
                SliverToBoxAdapter(child: _buildMacroPager(state)),
                SliverToBoxAdapter(child: _buildRecentLogsSection()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final todayIndex = DateTime.now().weekday % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HÔM NAY, ${DateTime.now().day} THÁNG ${DateTime.now().month}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text('Tổng quan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday = i == todayIndex;
              final isSelected = i == _selectedWeekday;
              final isFuture = i > todayIndex;
              final selectedDate = DateTime.now().subtract(
                Duration(days: todayIndex - i),
              );
              return Opacity(
                opacity: isFuture ? 0.4 : 1.0,
                child: GestureDetector(
                  onTap: isFuture
                      ? null
                      : () {
                          setState(() => _selectedWeekday = i);
                          context
                              .read<MetricsCubit>()
                              .loadMetricsForDate(selectedDate);
                          context
                              .read<RecentLogsCubit>()
                              .loadRecentLogs(selectedDate);
                        },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: isSelected
                            ? 36
                            : isToday
                                ? 40
                                : 32,
                        height: isSelected
                            ? 36
                            : isToday
                                ? 40
                                : 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          border: isToday
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isFuture
                                ? Colors.grey
                                : isSelected
                                    ? Colors.white
                                    : isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.white70,
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          child: Text(days[i]),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(MetricsLoaded state) {
    final data = state.metrics;
    final target = (data['target_calories'] as num).toInt();
    final remaining = (data['remaining_calories'] as num).toInt();
    final eaten = (data['calories_consumed'] as num).toInt();
    final burned = (data['calories_burned'] as num).toInt();

    final pct = target > 0 ? (eaten / target).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mục tiêu Calo',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () {},
                    child: Text('Xem báo cáo',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Circle + Remaining
              SizedBox(
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 140,
                      width: 140,
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 12,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$remaining',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Calo được phép',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Stats row: Goal / Eaten / Burned
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('assets/icons/target.png', target, 'Mục tiêu'),
                  _statItem('assets/icons/eat.png', eaten, 'Đã ăn'),
                  _statItem('assets/icons/calories.png', burned, 'Đã đốt'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String icon, int value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(icon, width: 20, height: 20),
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPager(MetricsLoaded state) {
    final data = state.metrics;
    final macros = Map<String, dynamic>.from(data['macros'] as Map);
    final eatenMacros =
        Map<String, dynamic>.from(data['macros_consumed'] as Map);

    final pGoal = (macros['protein'] as num).toDouble();
    final cGoal = (macros['carbs'] as num).toDouble();
    final fGoal = (macros['fat'] as num).toDouble();

    final pEat = (eatenMacros['protein'] as num).toDouble();
    final cEat = (eatenMacros['carbs'] as num).toDouble();
    final fEat = (eatenMacros['fat'] as num).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildMacroItem('assets/icons/proteins.png', 'Chất đạm', pEat,
                  pGoal, Colors.redAccent),
              const SizedBox(width: 12),
              _buildMacroItem('assets/icons/carb.png', 'Đường bột', cEat, cGoal,
                  Colors.orangeAccent),
              const SizedBox(width: 12),
              _buildMacroItem('assets/icons/fat.png', 'Chất béo', fEat, fGoal,
                  Colors.greenAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroItem(
      String icon, String label, double value, double goal, Color color) {
    final pct = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(icon, width: 20, height: 20),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text('${value.toStringAsFixed(1)}/${goal.toStringAsFixed(1)}g',
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentLogsSection() {
    return BlocBuilder<RecentLogsCubit, RecentLogsState>(
      builder: (context, state) {
        if (state is RecentLogsLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        } else if (state is RecentLogsError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi: ${state.message}'),
          );
        } else if (state is RecentLogsLoaded) {
          final meals = state.logs.where((l) => l.type == 'meal').toList();
          final exercises =
              state.logs.where((l) => l.type == 'exercise').toList();
          if (meals.isEmpty && exercises.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: Text('Chưa có dữ liệu',
                      style: TextStyle(color: Colors.white30))),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Nhật ký gần đây',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
