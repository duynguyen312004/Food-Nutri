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
    // Fetch metrics cho ngày hôm nay khi widget khởi tạo
    context.read<MetricsCubit>().loadMetricsForDate(DateTime.now());
    context.read<RecentLogsCubit>().loadRecentLogs(DateTime.now());
    // fetch presence cho cả tuần
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
                SliverToBoxAdapter(child: _buildRecentLogsSection(context)),

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

  Widget _buildCalorieCard(MetricsState state) {
    final data = (state as MetricsLoaded).metrics;
    final tdee = (data['tdee'] as num).toDouble().toInt();
    final remainingCalories =
        (data['remaining_calories'] as num).toDouble().toInt();
    final consumed = (data['calories_consumed'] as num).toDouble().toInt();
    final burned = (data['calories_burned'] as num).toDouble().toInt();

    final pct = tdee > 0 ? (remainingCalories / tdee).clamp(0.0, 1.0) : 0.0;

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
                        Text('$remainingCalories',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Calo còn lại',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Stats row: Goal / Consumed / Burned
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('assets/icons/target.png', tdee, 'Mục tiêu'),
                  _statItem('assets/icons/eat.png', consumed, 'Đã ăn'),
                  _statItem('assets/icons/calories.png', burned, 'Đã đốt'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String assetPath, int value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(assetPath, width: 20, height: 20),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPager(MetricsState state) {
    final data = (state as MetricsLoaded).metrics;
    final macros = Map<String, dynamic>.from(data['macros'] as Map);
    final eatenMacros =
        Map<String, dynamic>.from(data['macros_consumed'] as Map);
    final eatenProtein = (eatenMacros['protein'] ?? 0) as num;
    final eatenCarbs = (eatenMacros['carbs'] ?? 0) as num;
    final eatenFat = (eatenMacros['fat'] ?? 0) as num;

    final proteinGoal = (macros['protein'] ?? 0) as num;
    final carbsGoal = (macros['carbs'] ?? 0) as num;
    final fatGoal = (macros['fat'] ?? 0) as num;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildMacroItem(
                iconPath: 'assets/icons/proteins.png',
                label: 'Chất đạm',
                value: eatenProtein.toDouble(),
                goal: proteinGoal.toDouble(),
                color: Colors.redAccent,
              ),
              const SizedBox(width: 12),
              _buildMacroItem(
                iconPath: 'assets/icons/carb.png',
                label: 'Đường bột',
                value: eatenCarbs.toDouble(),
                goal: carbsGoal.toDouble(),
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 12),
              _buildMacroItem(
                iconPath: 'assets/icons/fat.png',
                label: 'Chất béo',
                value: eatenFat.toDouble(),
                goal: fatGoal.toDouble(),
                color: Colors.greenAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroItem({
    required String iconPath,
    required String label,
    required double value,
    required double goal,
    required Color color,
  }) {
    final pct = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(iconPath, width: 20, height: 20),
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
          Text('$value/${goal}g', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentLogsSection(BuildContext context) {
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
          // --- Chưa có dữ liệu thì show placeholder ---
          if (meals.isEmpty && exercises.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                // cho tất cả children canh sang trái
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề nằm bên trái
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Nhật ký gần đây",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Phần placeholder nằm giữa
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_menu_outlined,
                            size: 48, color: Colors.white30),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có dữ liệu',
                          style: TextStyle(fontSize: 16, color: Colors.white30),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // --- Ngược lại thì vẽ các card meal + exercise như trước ---
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // tiêu đề
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Nhật ký gần đây",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                // --- Meal cards ---
                ...meals.map((log) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Theme.of(context).cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: log.imageUrl != null
                                    ? Image.network(log.imageUrl!,
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover)
                                    : Image.asset('assets/icons/eat.png',
                                        width: 55, height: 55),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // tên
                                    Text(log.name,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    // per-unit & đã ăn
                                    if (log.perCalories != null &&
                                        log.quantity != null &&
                                        log.unit != null)
                                      Text(
                                        '${log.perCalories!.toStringAsFixed(0)} kcal/${log.unit} • Đã tiêu thụ ${log.quantity} ${log.unit}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70),
                                      ),
                                    const SizedBox(height: 6),
                                    // macros
                                    Row(
                                      children: [
                                        Image.asset('assets/icons/proteins.png',
                                            width: 16, height: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                            '${log.protein?.toStringAsFixed(1)}g',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 12),
                                        Image.asset('assets/icons/carb.png',
                                            width: 16, height: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                            '${log.carbs?.toStringAsFixed(1)}g',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 12),
                                        Image.asset('assets/icons/fat.png',
                                            width: 16, height: 16),
                                        const SizedBox(width: 4),
                                        Text('${log.fat?.toStringAsFixed(1)}g',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // tổng calo tiêu thụ
                                    Text(
                                      '${log.calories?.toStringAsFixed(0)} kcal',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white60),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),

                // --- Exercise cards ---
                ...exercises.map((log) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Theme.of(context).cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // badge duration
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                ),
                                child: Text(
                                  '${log.durationMin ?? 0}ʼ',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log.name,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    if (log.category != null) ...[
                                      const SizedBox(height: 2),
                                      Text(log.category!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white70,
                                              fontStyle: FontStyle.italic)),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                        'Đốt ${log.caloriesBurned?.toStringAsFixed(0)} kcal',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white60)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
