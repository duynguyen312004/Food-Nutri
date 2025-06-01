// 📄 JournalPage: Hiển thị nhật ký dinh dưỡng theo giờ trong ngày, gồm metrics, meal/water/exercise logs.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/food/recipe_cubit.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../blocs/metrics/metrics_state.dart';
import '../../blocs/log/journal_cubit.dart';
import '../../blocs/log/journal_state.dart';
import '../../models/log_entry.dart';
import '../../widgets/fast_image.dart';
import 'add_entry_page.dart';
import 'food_detail_page.dart';
import 'package:nutrition_app/utils/dialog_helper.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage>
    with AutomaticKeepAliveClientMixin {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 🟣 Khi page được tạo xong, load metrics và logs cho ngày hiện tại

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMetricsAndLogs());
  }
  // 🟣 Hàm này dùng để load lại metrics và logs nếu dữ liệu chưa được load hoặc không khớp ngày

  void _loadMetricsAndLogs() {
    final metrics = context.read<MetricsCubit>().state;
    final journal = context.read<JournalCubit>().state;

    if (metrics is! MetricsLoaded ||
        !_isSameDate(metrics.date, _selectedDate)) {
      context.read<MetricsCubit>().loadMetricsForDate(_selectedDate);
    }
    if (journal is! JournalLoaded ||
        !_isSameDate(journal.date, _selectedDate)) {
      context.read<JournalCubit>().loadLogs(_selectedDate);
    }
  }
  // 🔹 So sánh 2 ngày có giống nhau không (bỏ qua giờ phút)

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context), // 🔹 Header chuyển ngày
            _buildMetricsRow(), // 🔹 Dòng tổng hợp metrics
            Expanded(child: _buildTimeline()), // 🔹 Timeline theo giờ
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // 🔹 Đảm bảo không bị dispose khi chuyển tab
// 🟣 Header với nút chuyển ngày
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() => _selectedDate =
                  _selectedDate.subtract(const Duration(days: 1)));
              _loadMetricsAndLogs();
            },
          ),
          Text(
            DateFormat('dd/MM/yyyy').format(_selectedDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final tomorrow = _selectedDate.add(const Duration(days: 1));
              if (!tomorrow.isAfter(DateTime.now())) {
                setState(() => _selectedDate = tomorrow);
                _loadMetricsAndLogs();
              }
            },
          )
        ],
      ),
    );
  }

// 🟣 Dòng metrics gồm calories, protein, carb, fat, nước, calo đốt
  Widget _buildMetricsRow() {
    return BlocBuilder<MetricsCubit, MetricsState>(
      builder: (context, state) {
        if (state is! MetricsLoaded) return const SizedBox(height: 80);
        final m = state.metrics;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _buildSmartMetric(
                iconPath: 'assets/icons/kcal.png',
                consumed: m['calories_consumed'],
                target: m['calories_consumed'] + m['remaining_calories'],
                unit: 'kcal',
                color: Colors.purpleAccent,
              ),
              _buildSmartMetric(
                iconPath: 'assets/icons/proteins.png',
                consumed: m['macros_consumed']['protein'],
                target: m['macros']['protein'],
                unit: 'g',
                color: Colors.redAccent,
              ),
              _buildSmartMetric(
                iconPath: 'assets/icons/carb.png',
                consumed: m['macros_consumed']['carbs'],
                target: m['macros']['carbs'],
                unit: 'g',
                color: Colors.orangeAccent,
              ),
              _buildSmartMetric(
                iconPath: 'assets/icons/fat.png',
                consumed: m['macros_consumed']['fat'],
                target: m['macros']['fat'],
                unit: 'g',
                color: Colors.greenAccent,
              ),
              _buildMetricTile(
                'assets/icons/water.png',
                '${(m['water_intake_ml'] as num).toInt()} ml',
                Colors.blueAccent,
                0,
              ),
              _buildMetricTile(
                'assets/icons/calories.png',
                '${(m['calories_burned'] as num).toInt()} kcal',
                Colors.redAccent,
                0,
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 Tạo metric dạng progress bar thông minh có consumed/target
  Widget _buildSmartMetric({
    required String iconPath,
    required num consumed,
    required num target,
    required String unit,
    required Color color,
  }) {
    final percent = target == 0 ? 0.0 : consumed / target;
    final label =
        '${consumed.toStringAsFixed(1)}/${target.toStringAsFixed(1)} $unit';
    return _buildMetricTile(iconPath, label, color, percent);
  }

// 🔹 Widget nhỏ hiển thị mỗi chỉ số (dưới dạng thanh)
  Widget _buildMetricTile(
      String iconPath, String label, Color color, double percent) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: _MetricTile(
        iconPath: iconPath,
        label: label,
        color: color,
        percent: percent,
      ),
    );
  }

// 🟣 Tạo timeline từ 0h đến 23h, mỗi giờ là 1 block
  Widget _buildTimeline() {
    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) {
        if (state is! JournalLoaded) return const SizedBox.shrink();
        final logs = state.logs;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: 24,
          itemBuilder: (context, hour) => _buildHourBlock(context, hour, logs),
        );
      },
    );
  }
// 🟣 Hiển thị mỗi giờ trong ngày, gồm giờ + tổng hợp meal (nếu có) + nút thêm log + các log (meal, water, exercise)

  Widget _buildHourBlock(BuildContext context, int hour, List<LogEntry> logs) {
    final label = '${hour.toString().padLeft(2, '0')}:00';
    final entries = logs.where((e) => e.timestamp.hour == hour).toList();
    final meals = entries.where((e) => e.type == 'meal').toList();
    final waters = entries.where((e) => e.type == 'water').toList();
    final exercises = entries.where((e) => e.type == 'exercise').toList();

    final cal = meals.fold<num>(0, (sum, e) => sum + (e.data['calories'] ?? 0));
    final protein =
        meals.fold<num>(0, (sum, e) => sum + (e.data['protein'] ?? 0));
    final carb = meals.fold<num>(0, (sum, e) => sum + (e.data['carbs'] ?? 0));
    final fat = meals.fold<num>(0, (sum, e) => sum + (e.data['fat'] ?? 0));

    final hasLogs =
        meals.isNotEmpty || waters.isNotEmpty || exercises.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: hasLogs
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasLogs
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Dải tổng hợp macro meal
              Expanded(
                child: meals.isNotEmpty
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSummaryIcon(
                                'kcal.png', '${cal.round()} kcal'),
                            _buildSummaryIcon(
                                'proteins.png', '${protein.round()}g'),
                            _buildSummaryIcon('carb.png', '${carb.round()}g'),
                            _buildSummaryIcon('fat.png', '${fat.round()}g'),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary),
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
                  if (result == true) _loadMetricsAndLogs();
                },
              ),
            ],
          ),
          ...meals.map((e) => _buildDismissibleLog(
              context,
              e,
              GestureDetector(
                onTap: () async {
                  final quantity = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(
                              value: context.read<JournalCubit>().foodCubit),
                          BlocProvider(create: (_) => RecipeCubit()),
                        ],
                        child: FoodDetailPage(
                          foodId: e.data['food_item_id'],
                          initialQuantity:
                              (e.data['quantity'] as num).toDouble(),
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
                  }
                },
                child: _MealCard(log: e),
              ))),
          ...waters
              .map((e) => _buildDismissibleLog(context, e, _WaterCard(log: e))),
          ...exercises.map(
              (e) => _buildDismissibleLog(context, e, _ExerciseCard(log: e))),
        ],
      ),
    );
  }

// 🔹 Tạo icon + text nhỏ (calories, protein, carb, fat) hiển thị tổng hợp meal trong từng giờ

  Widget _buildSummaryIcon(String iconName, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          Image.asset('assets/icons/$iconName', width: 16, height: 16),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
// 🔹 Bọc log trong Dismissible để có thể vuốt xóa, xử lý xoá log và hiển thị dialog xác nhận

  Widget _buildDismissibleLog(BuildContext context, LogEntry e, Widget child) {
    return Dismissible(
      key: ValueKey('${e.type}-${e.logId}-${e.timestamp}'),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<JournalCubit>().deleteLog(e);
        final msg = e.type == 'meal'
            ? 'Đã xoá món ăn: ${e.data['name']}'
            : e.type == 'water'
                ? 'Đã xoá log nước'
                : 'Đã xoá bài tập: ${e.data['name']}';
        showDeleteDialog(context, msg);
      },
      child: child,
    );
  }
}
// 🟣 Hiển thị thông tin món ăn đã log: hình ảnh, tên món, khẩu phần và thành phần dinh dưỡng (calo, protein, carb, fat)

class _MealCard extends StatelessWidget {
  final LogEntry log;
  const _MealCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final name = log.data['name'] ?? '';
    final quantity = log.data['quantity'];
    final unit = log.data['unit'];
    final img = log.data['image_url'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FastImage(
                imagePath: img ?? '',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context)
                            .style
                            .copyWith(fontSize: 14),
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' • ${quantity.toStringAsFixed(1)}$unit',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _iconText('kcal.png',
                            '${(log.data['calories'] as num).toDouble().toStringAsFixed(1)} kcal'),
                        const SizedBox(width: 10),
                        _iconText('proteins.png',
                            '${(log.data['protein'] as num).toDouble().toStringAsFixed(1)}g'),
                        const SizedBox(width: 10),
                        _iconText('carb.png',
                            '${(log.data['carbs'] as num).toDouble().toStringAsFixed(1)}g'),
                        const SizedBox(width: 10),
                        _iconText('fat.png',
                            '${(log.data['fat'] as num).toDouble().toStringAsFixed(1)}g'),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
// 🔹 Dùng trong _MealCard để render icon + giá trị dinh dưỡng nhỏ gọn (ví dụ: 🥩 20g)

  Widget _iconText(String icon, String text) {
    return Row(
      children: [
        Image.asset('assets/icons/$icon', width: 16, height: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}
// 🟣 Hiển thị log uống nước: đơn giản chỉ gồm icon ly nước và số ml

class _WaterCard extends StatelessWidget {
  final LogEntry log;
  const _WaterCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final ml = log.data['intake_ml'] ?? 0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.local_drink, color: Colors.blueAccent),
        title: Text('$ml ml nước'),
      ),
    );
  }
}
// 🟣 Hiển thị log bài tập: tên bài tập, thời lượng (phút), lượng calo đã đốt

class _ExerciseCard extends StatelessWidget {
  final LogEntry log;
  const _ExerciseCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final duration = log.data['duration_min'] ?? 0;
    final burned = log.data['calories_burned'] ?? 0;
    final name = log.data['name'] ?? '';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.fitness_center, color: Colors.redAccent),
        title: Text(
          name,
          style:
              const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        subtitle: Text('$duration phút • $burned kcal'),
      ),
    );
  }
}
// 🟣 Một ô nhỏ hiển thị icon, label (dạng số liệu ví dụ: 300/500 kcal) và thanh progress biểu thị tỉ lệ hoàn thành mục tiêu

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
      width: 150,
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: percent > 1.0 ? Colors.redAccent : null,
              ),
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
