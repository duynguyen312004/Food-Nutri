import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../blocs/metrics/metrics_state.dart';
import '../../blocs/log/journal_cubit.dart';
import '../../blocs/log/journal_state.dart';
import '../../models/log_entry.dart';
import 'add_entry_page.dart';

/// Màn Nhật ký chính, hiển thị metrics và timeline các hoạt động trong ngày
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _JournalPageState createState() => _JournalPageState();
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
        // Thanh chọn ngày
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
        // Metrics bar
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
                      _MetricTile(
                        iconPath: 'assets/icons/kcal.png',
                        label:
                            '${m['calories_consumed'].toInt()}/${m['remaining_calories'].toInt()}',
                        color: Colors.purpleAccent,
                        percent:
                            m['calories_consumed'] / m['remaining_calories'],
                      ),
                      const SizedBox(width: 8),
                      _MetricTile(
                        iconPath: 'assets/icons/proteins.png',
                        label:
                            '${m['macros_consumed']['protein'].toDouble()}/${m['macros']['protein'].toDouble()}',
                        color: Colors.redAccent,
                        percent: m['macros_consumed']['protein'] /
                            m['macros']['protein'],
                      ),
                      const SizedBox(width: 8),
                      _MetricTile(
                        iconPath: 'assets/icons/carb.png',
                        label:
                            '${m['macros_consumed']['carbs'].toDouble()}/${m['macros']['carbs'].toDouble()}',
                        color: Colors.orangeAccent,
                        percent: m['macros_consumed']['carbs'] /
                            m['macros']['carbs'],
                      ),
                      const SizedBox(width: 8),
                      _MetricTile(
                        iconPath: 'assets/icons/fat.png',
                        label:
                            '${m['macros_consumed']['fat'].toDouble()}/${m['macros']['fat'].toDouble()}',
                        color: Colors.greenAccent,
                        percent:
                            m['macros_consumed']['fat'] / m['macros']['fat'],
                      ),
                      const SizedBox(width: 8),

                      _MetricTile(
                        iconPath: 'assets/icons/calories.png', // icon đốt calo
                        label: '${m['calories_burned'].toInt()} kcal',
                        color: Colors.redAccent,
                        percent: 0.0, // hoặc tính % nếu có target đốt
                      ),
                      const SizedBox(width: 8),

                      // 2. Ô nước đã uống
                      _MetricTile(
                        iconPath: 'assets/icons/water.png', // icon nước
                        label: '${m['water_intake_ml'].toInt()} ml',
                        color: Colors.blueAccent,
                        percent: 0.0, // hoặc tính % nếu có target nước
                      ),
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
            // Lọc toàn bộ entries của khung giờ này
            final entries =
                logs.where((e) => e.timestamp.hour == hour).toList();
            final hasEntry = entries.isNotEmpty;
            // Tách riêng từng loại
            final meals = entries.where((e) => e.type == 'meal').toList();
            final waters = entries.where((e) => e.type == 'water').toList();
            final exercises =
                entries.where((e) => e.type == 'exercise').toList();
            final hasMeals = meals.isNotEmpty;

            // Tính tổng calo & macros chỉ từ meals
            final cals = meals.fold<double>(
              0.0,
              (sum, e) =>
                  sum + ((e.data['calories'] as num?)?.toDouble() ?? 0.0),
            );
            final p = meals.fold<double>(
              0.0,
              (sum, e) =>
                  sum + ((e.data['protein'] as num?)?.toDouble() ?? 0.0),
            );
            final cb = meals.fold<double>(
              0.0,
              (sum, e) => sum + ((e.data['carbs'] as num?)?.toDouble() ?? 0.0),
            );
            final f = meals.fold<double>(
              0.0,
              (sum, e) => sum + ((e.data['fat'] as num?)?.toDouble() ?? 0.0),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh giờ + summary + nút +
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // time badge
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
                            color: hasMeals ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // summary meals
                      if (hasMeals)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Image.asset('assets/icons/calories.png',
                                    width: 12, height: 12),
                                const SizedBox(width: 4),
                                Text('${cals.toDouble()} cal',
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 12),
                                Image.asset('assets/icons/proteins.png',
                                    width: 12, height: 12),
                                const SizedBox(width: 4),
                                Text('${p.toDouble()}g',
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 12),
                                Image.asset('assets/icons/carb.png',
                                    width: 12, height: 12),
                                const SizedBox(width: 4),
                                Text('${cb.toDouble()}g',
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 12),
                                Image.asset('assets/icons/fat.png',
                                    width: 12, height: 12),
                                const SizedBox(width: 4),
                                Text('${f.toDouble()}g',
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      if (hasMeals)
                        const SizedBox(
                          width: 10,
                        )
                      else
                        const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddEntryPage()),
                          );
                          _loadForDate(_selectedDate);
                        },
                      ),
                    ],
                  ),
                ),

                // Danh sách meals
                if (meals.isNotEmpty) ...meals.map((e) => _MealCard(log: e)),

                // Danh sách water logs
                if (waters.isNotEmpty) ...waters.map((e) => _WaterCard(log: e)),

                // Danh sách exercise logs
                if (exercises.isNotEmpty)
                  ...exercises.map((e) => _ExerciseCard(log: e)),
              ],
            );
          },
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color color;
  final double percent;

  const _MetricTile({
    required this.iconPath,
    required this.label,
    required this.color,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, // mỗi ô cố định độ rộng
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 20, height: 20),
          const SizedBox(height: 8),

          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          // progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
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
                      width: 48, height: 48, fit: BoxFit.cover))
              : const Icon(Icons.fastfood),
          title: Text(
            '$name • $quantity$unit',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Row(children: [
            Text('${log.data['calories']} cal',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Image.asset('assets/icons/proteins.png', width: 12, height: 12),
            Text(' ${log.data['protein']}g',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Image.asset('assets/icons/carb.png', width: 12, height: 12),
            Text(' ${log.data['carbs']}g',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Image.asset('assets/icons/fat.png', width: 12, height: 12),
            Text(' ${log.data['fat']}g', style: const TextStyle(fontSize: 12)),
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
