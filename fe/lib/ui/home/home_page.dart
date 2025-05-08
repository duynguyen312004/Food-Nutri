import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../blocs/metrics/metrics_state.dart';

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
    // Fetch metrics cho ngày hôm nay khi widget khởi tạo
    context.read<MetricsCubit>().loadMetricsForDate(DateTime.now());
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
            // state is MetricsLoaded
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildCalorieCard(state)),
                SliverToBoxAdapter(child: _buildMacroPager(state)),
                // Các sliver khác (ActionButtons, logs...) sẽ thêm sau
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
                      // TODO: dot indicator nếu có dữ liệu
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

  Widget _buildCalorieCard(MetricsState state) {
    final data = (state as MetricsLoaded).metrics;
    final tdee = (data['tdee'] as num).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
              SizedBox(
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 140,
                      width: 140,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 12,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${tdee.toInt()}',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Calo mục tiêu',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroPager(MetricsState state) {
    final data = (state as MetricsLoaded).metrics;
    final macros = Map<String, dynamic>.from(data['macros'] as Map);
    final proteinGoal = (macros['protein'] ?? 0) as num;
    final carbsGoal = (macros['carbs'] ?? 0) as num;
    final fatGoal = (macros['fat'] ?? 0) as num;
    const eaten = 0;
    final items = [
      {'label': 'Chất đạm', 'value': eaten, 'goal': proteinGoal},
      {'label': 'Đường bột', 'value': eaten, 'goal': carbsGoal},
      {'label': 'Chất béo', 'value': eaten, 'goal': fatGoal},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((m) {
              final value = m['value'] as num;
              final goal = m['goal'] as num;
              final pct = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
              return Expanded(
                child: Column(
                  children: [
                    Text(m['label'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: pct, backgroundColor: Colors.white12),
                    const SizedBox(height: 4),
                    Text('${value.toInt()}/${goal.toInt()}g'),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statLabel(String value, String label) => Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
