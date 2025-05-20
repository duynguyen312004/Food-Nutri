import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../blocs/metrics/metrics_state.dart';
import '../../blocs/log/journal_cubit.dart';
import '../../blocs/log/journal_state.dart';
import '../../models/log_entry.dart';
import 'add_entry_page.dart';
import 'food_detail_page.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadForDate(_selectedDate);
  }

  void _loadForDate(DateTime date) {
    setState(() => _selectedDate = date);
    context.read<MetricsCubit>().loadMetricsForDate(date);
    context.read<JournalCubit>().loadLogs(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildTimeline()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => _loadForDate(
                    _selectedDate.subtract(const Duration(days: 1))),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                onPressed: () {
                  final tomorrow = _selectedDate.add(const Duration(days: 1));
                  if (!tomorrow.isAfter(DateTime.now())) _loadForDate(tomorrow);
                },
              ),
            ],
          ),
        ),
        BlocBuilder<MetricsCubit, MetricsState>(
          builder: (context, state) {
            if (state is MetricsLoaded) {
              final m = state.metrics;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMetricTile(
                          'assets/icons/kcal.png',
                          '${m['calories_consumed'].toInt()}/${m['remaining_calories'].toInt() + m['calories_consumed'].toInt()} kcal',
                          Colors.purpleAccent,
                          m['calories_consumed'] / m['remaining_calories']),
                      _buildMetricTile(
                          'assets/icons/proteins.png',
                          '${m['macros_consumed']['protein'].toDouble()}/${m['macros']['protein'].toDouble()} g',
                          Colors.redAccent,
                          m['macros_consumed']['protein'] /
                              m['macros']['protein']),
                      _buildMetricTile(
                          'assets/icons/carb.png',
                          '${m['macros_consumed']['carbs'].toDouble()}/${m['macros']['carbs'].toDouble()} g',
                          Colors.orangeAccent,
                          m['macros_consumed']['carbs'] / m['macros']['carbs']),
                      _buildMetricTile(
                          'assets/icons/fat.png',
                          '${m['macros_consumed']['fat'].toDouble()}/${m['macros']['fat'].toDouble()} g',
                          Colors.greenAccent,
                          m['macros_consumed']['fat'] / m['macros']['fat']),
                      _buildMetricTile(
                          'assets/icons/calories.png',
                          '${m['calories_burned'].toInt()} kcal',
                          Colors.redAccent,
                          0),
                      _buildMetricTile(
                          'assets/icons/water.png',
                          '${m['water_intake_ml'].toInt()} ml',
                          Colors.blueAccent,
                          0),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox(height: 80);
          },
        ),
      ],
    );
  }

  Widget _buildMetricTile(
      String iconPath, String label, Color color, double percent) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: _MetricTile(
        iconPath: iconPath,
        label: label,
        color: color,
        percent: percent.clamp(0.0, 1.0),
      ),
    );
  }

  Widget _buildTimeline() {
    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) {
        if (state is JournalLoading || state is JournalInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is JournalError) {
          return Center(child: Text('Lỗi: ${state.message}'));
        }
        final logs = (state as JournalLoaded).logs;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: 24,
          itemBuilder: (context, hour) {
            final label = '${hour.toString().padLeft(2, '0')}:00';
            final entries =
                logs.where((e) => e.timestamp.hour == hour).toList();
            final hasEntry = entries.isNotEmpty;
            final meals = entries.where((e) => e.type == 'meal').toList();
            final waters = entries.where((e) => e.type == 'water').toList();
            final exercises =
                entries.where((e) => e.type == 'exercise').toList();
            final hasMeals = meals.isNotEmpty;

            final cals = meals.fold<double>(0.0,
                (sum, e) => sum + ((e.data['calories'] as num?)?.toInt() ?? 0));
            final p = meals.fold<double>(
                0.0,
                (sum, e) =>
                    sum + ((e.data['protein'] as num?)?.toDouble() ?? 0));
            final cb = meals.fold<double>(0.0,
                (sum, e) => sum + ((e.data['carbs'] as num?)?.toDouble() ?? 0));
            final f = meals.fold<double>(0.0,
                (sum, e) => sum + ((e.data['fat'] as num?)?.toDouble() ?? 0));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasEntry
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                              color: hasMeals ? Colors.white : Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasMeals)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Image.asset('assets/icons/kcal.png',
                                    width: 16, height: 16),
                                const SizedBox(width: 6),
                                Text('${cals.toInt()} kcal',
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Image.asset('assets/icons/proteins.png',
                                    width: 16, height: 16),
                                const SizedBox(width: 6),
                                Text('${p.toDouble()}g',
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Image.asset('assets/icons/carb.png',
                                    width: 16, height: 16),
                                const SizedBox(width: 6),
                                Text('${cb.toDouble()}g',
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Image.asset('assets/icons/fat.png',
                                    width: 16, height: 16),
                                const SizedBox(width: 6),
                                Text('${f.toDouble()}g',
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      if (hasMeals)
                        const SizedBox(width: 8)
                      else
                        const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEntryPage(
                                selectedDate: _selectedDate,
                                selectedHour: hour,
                              ),
                            ),
                          );
                          if (result == true) _loadForDate(_selectedDate);
                        },
                      ),
                    ],
                  ),
                ),
                ...meals.map((e) => Dismissible(
                      key: ValueKey('meal-${e.logId}-${e.timestamp}'),
                      direction: DismissDirection.endToStart,
                      background: _buildDismissBg(),
                      onDismissed: (_) {
                        context.read<JournalCubit>().deleteLog(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Đã xoá món ăn: ${e.data['name']}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.redAccent),
                        );
                        _loadForDate(_selectedDate);
                      },
                      child: GestureDetector(
                        onTap: () async {
                          final quantity = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<JournalCubit>().foodCubit,
                                child: FoodDetailPage(
                                  foodId: e.data['food_item_id'],
                                  initialQuantity:
                                      e.data['quantity'].toDouble(),
                                  isEditing: true,
                                  timestamp: e.timestamp,
                                ),
                              ),
                            ),
                          );
                          if (!context.mounted) return;
                          if (quantity != null &&
                              quantity is double &&
                              quantity != e.data['quantity']) {
                            context.read<JournalCubit>().updateMealQuantity(
                                  e.logId,
                                  quantity,
                                  timestamp: e.timestamp,
                                );

                            context
                                .read<MetricsCubit>()
                                .loadMetricsForDate(_selectedDate);

                            _loadForDate(_selectedDate); // reload logs

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã cập nhật khẩu phần món ăn'),
                                  backgroundColor: Colors.blueAccent,
                                ),
                              );
                            }
                          }
                        },
                        child: _MealCard(log: e),
                      ),
                    )),
                ...waters.map((e) => Dismissible(
                      key: ValueKey('water-${e.logId}'),
                      direction: DismissDirection.endToStart,
                      background: _buildDismissBg(),
                      onDismissed: (_) {
                        context.read<JournalCubit>().deleteLog(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã xoá log nước'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.redAccent),
                        );
                        _loadForDate(_selectedDate);
                      },
                      child: _WaterCard(log: e),
                    )),
                ...exercises.map((e) => Dismissible(
                      key: ValueKey('exercise-${e.logId}'),
                      direction: DismissDirection.endToStart,
                      background: _buildDismissBg(),
                      onDismissed: (_) {
                        context.read<JournalCubit>().deleteLog(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Đã xoá bài tập: ${e.data['name']}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.redAccent),
                        );
                        _loadForDate(_selectedDate);
                      },
                      child: _ExerciseCard(log: e),
                    )),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDismissBg() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color color;
  final double percent;

  const _MetricTile(
      {required this.iconPath,
      required this.label,
      required this.color,
      required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 18, height: 18),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// Card riêng cho mỗi entry
class _MealCard extends StatelessWidget {
  final LogEntry log;
  const _MealCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final name = log.data['name'];
    final quantity = log.data['quantity'];
    final unit = log.data['unit'];

    final img = log.data['image_url'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Theme.of(context).cardColor,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: img != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(img,
                      width: 64, height: 64, fit: BoxFit.cover))
              : const Icon(Icons.fastfood),
          title: Text(
            '$name • $quantity$unit',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Row(children: [
            Text('${(log.data['calories'] as num?)?.toInt()} kcal',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Image.asset('assets/icons/proteins.png', width: 14, height: 14),
            Text(' ${log.data['protein']}g',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Image.asset('assets/icons/carb.png', width: 14, height: 14),
            Text(' ${log.data['carbs']}g',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Image.asset('assets/icons/fat.png', width: 14, height: 14),
            Text(' ${log.data['fat']}g', style: const TextStyle(fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final LogEntry log;
  const _WaterCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final ml = (log.data['intake_ml'] as num?)?.toInt() ?? 0;
    final time = DateFormat.Hm().format(log.timestamp);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Card(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.local_drink, color: Colors.lightBlueAccent),
          title: Text('$ml ml nước'),
          subtitle: Text(time,
              style: const TextStyle(fontSize: 12, color: Colors.white60)),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final LogEntry log;
  const _ExerciseCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final mins = (log.data['duration_min'] as num?)?.toInt() ?? 0;
    final cal = (log.data['calories_burned'] as num?)?.toInt() ?? 0;
    final name = log.data['name'] as String? ?? 'Tập luyện';
    final time = DateFormat.Hm().format(log.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Card(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.fitness_center, color: Colors.redAccent),
          title:
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '$mins phút • Đốt $cal kcal • $time',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ),
      ),
    );
  }
}
