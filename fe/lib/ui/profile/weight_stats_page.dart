import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../blocs/log/weight_log_cubit.dart';
import '../../blocs/log/weight_log_state.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../utils/dialog_helper.dart'; // Đảm bảo file này có showSuccessDialog
import 'weight_history_page.dart';

class WeightStatsPage extends StatefulWidget {
  final double? targetWeight;

  const WeightStatsPage({super.key, this.targetWeight});

  @override
  State<WeightStatsPage> createState() => _WeightStatsPageState();
}

class _WeightStatsPageState extends State<WeightStatsPage> {
  int _selectedTab = 0;
  late DateTime _displayDate;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  // Để nhận biết sau khi log xong thì show dialog, reload metrics nếu cần
  bool _pendingAddWeight = false;
  DateTime? _lastLoggedDate;

  @override
  void initState() {
    super.initState();
    _displayDate = DateTime.now();
    _setRangeAndFetch();
  }

  String _getRangeLabel() {
    if (_selectedTab == 0) {
      return DateFormat('MM/yyyy').format(_displayDate);
    } else if (_selectedTab == 1) {
      int startMonth = _displayDate.month - 5;
      int startYear = _displayDate.year;
      if (startMonth <= 0) {
        startMonth += 12;
        startYear -= 1;
      }
      DateTime rangeStart = DateTime(startYear, startMonth, 1);
      DateTime rangeEnd = DateTime(_displayDate.year, _displayDate.month + 1, 1)
          .subtract(const Duration(days: 1));
      return '${DateFormat('MM/yyyy').format(rangeStart)} - ${DateFormat('MM/yyyy').format(rangeEnd)}';
    } else {
      return '${DateFormat('MM/yyyy').format(DateTime(_displayDate.year, 1, 1))} - ${DateFormat('MM/yyyy').format(DateTime(_displayDate.year, 12, 31))}';
    }
  }

  void _setRangeAndFetch() {
    if (_selectedTab == 0) {
      _rangeStart = DateTime(_displayDate.year, _displayDate.month, 1);
      _rangeEnd = DateTime(_displayDate.year, _displayDate.month + 1, 1)
          .subtract(const Duration(days: 1));
    } else if (_selectedTab == 1) {
      int startMonth = _displayDate.month - 5;
      int startYear = _displayDate.year;
      if (startMonth <= 0) {
        startMonth += 12;
        startYear -= 1;
      }
      _rangeStart = DateTime(startYear, startMonth, 1);
      _rangeEnd = DateTime(_displayDate.year, _displayDate.month + 1, 1)
          .subtract(const Duration(days: 1));
    } else {
      _rangeStart = DateTime(_displayDate.year, 1, 1);
      _rangeEnd = DateTime(_displayDate.year, 12, 31);
    }
    context.read<WeightLogCubit>().fetchWeightLogs(
          start: _rangeStart,
          end: _rangeEnd,
        );
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTab = index);
    _setRangeAndFetch();
  }

  void _onNavigateMonth(int delta) {
    final candidate = DateTime(_displayDate.year, _displayDate.month + delta);
    final now = DateTime.now();
    if (candidate.isAfter(DateTime(now.year, now.month, 1))) return;
    setState(() => _displayDate = candidate);
    _setRangeAndFetch();
  }

  void _openWeightHistory(List logs) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WeightHistoryPage(logs: logs),
    ));
  }

  void _onAddPressed() async {
    final choice = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Ghi lại cân nặng"),
                  onTap: () => Navigator.pop(context, 'log'),
                ),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text("Chỉnh cân nặng mục tiêu"),
                  onTap: () => Navigator.pop(context, 'goal'),
                )
              ],
            ));
    if (choice == 'log') _showAddWeightDialog();
    if (choice == 'goal') {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WeightLogCubit, WeightLogState>(
      listener: (context, state) async {
        if (state is WeightLogError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        // Xử lý thành công: show dialog helper, reload metrics nếu cần
        if (_pendingAddWeight && state is WeightLogLoaded) {
          _pendingAddWeight = false;
          if (_lastLoggedDate != null &&
              DateUtils.isSameDay(_lastLoggedDate, DateTime.now())) {
            context.read<MetricsCubit>().loadMetricsForDate(DateTime.now());
          }
          showSuccessDialog(context, "Đã ghi nhận cân nặng thành công!");
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text('Thống kê cân nặng',
              style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _onAddPressed,
            )
          ],
        ),
        body: BlocBuilder<WeightLogCubit, WeightLogState>(
          builder: (context, state) {
            if (state is WeightLogLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is WeightLogLoaded && state.logs.isNotEmpty) {
              final logs = state.logs;
              final sorted = logs.toList()
                ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
              final firstDate = sorted.first.loggedAt;
              final lastDate = sorted.last.loggedAt;
              final startWeight = sorted.first.weightKg;
              final currentWeight = sorted.last.weightKg;
              final change = (currentWeight - startWeight).toStringAsFixed(1);
              final changeColor = (currentWeight >= startWeight)
                  ? Colors.greenAccent
                  : Colors.redAccent;

              final spanDays = lastDate
                  .difference(firstDate)
                  .inDays
                  .toDouble()
                  .clamp(1, 1000);
              final weights = [
                ...sorted.map((e) => e.weightKg),
                if (widget.targetWeight != null) widget.targetWeight!,
              ];
              final minY =
                  (weights.reduce((a, b) => a < b ? a : b) / 10).floor() * 10.0;
              final maxY =
                  (weights.reduce((a, b) => a > b ? a : b) / 10).ceil() * 10.0;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      _buildTab('1 tháng', 0),
                      _buildTab('6 tháng', 1),
                      _buildTab('Năm', 2),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedTab == 0)
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _onNavigateMonth(-1),
                              icon: const Icon(Icons.arrow_back_ios,
                                  color: Colors.white70),
                            ),
                            Text(
                              _getRangeLabel(),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            IconButton(
                              onPressed: () => _onNavigateMonth(1),
                              icon: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white70),
                            ),
                          ],
                        )
                      else
                        Text(
                          _getRangeLabel(),
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Biểu đồ cân nặng',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.92,
                      child: SizedBox(
                        height: 190,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: spanDays.toDouble(),
                            minY: minY,
                            maxY: maxY,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: 5,
                              verticalInterval: (spanDays / 5).clamp(1, 100),
                              getDrawingHorizontalLine: (v) => const FlLine(
                                color: Colors.white12,
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (v) => const FlLine(
                                color: Colors.white10,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                left:
                                    BorderSide(color: Colors.white24, width: 1),
                                bottom:
                                    BorderSide(color: Colors.white24, width: 1),
                                right: BorderSide(color: Colors.transparent),
                                top: BorderSide(color: Colors.transparent),
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: spanDays /
                                      (sorted.length - 1 > 0
                                          ? sorted.length - 1
                                          : 1),
                                  getTitlesWidget: (x, _) {
                                    final date = firstDate
                                        .add(Duration(days: x.toInt()));
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        DateFormat('dd/MM').format(date),
                                        style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5,
                                  getTitlesWidget: (y, _) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      y.toInt().toString(),
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: sorted
                                    .map((e) => FlSpot(
                                        e.loggedAt
                                            .difference(firstDate)
                                            .inDays
                                            .toDouble(),
                                        e.weightKg))
                                    .toList(),
                                isCurved: false,
                                color: Colors.white,
                                barWidth: 2.2,
                                dotData: const FlDotData(show: true),
                              ),
                              if (widget.targetWeight != null)
                                LineChartBarData(
                                  spots: [
                                    FlSpot(spanDays.toDouble(),
                                        widget.targetWeight!),
                                  ],
                                  isCurved: false,
                                  color: Colors.purpleAccent,
                                  barWidth: 0,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, bar, index) =>
                                            FlDotCirclePainter(
                                      radius: 6,
                                      color: Colors.purpleAccent,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    ),
                                  ),
                                  showingIndicators: [0],
                                ),
                            ],
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                if (widget.targetWeight != null)
                                  HorizontalLine(
                                    y: widget.targetWeight!,
                                    color: Colors.purpleAccent,
                                    strokeWidth: 2,
                                    dashArray: [6, 4],
                                    label: HorizontalLineLabel(
                                      show: true,
                                      alignment: Alignment.topLeft,
                                      padding: const EdgeInsets.only(right: 8),
                                      style: const TextStyle(
                                        color: Colors.purpleAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      labelResolver: (_) => 'Mục tiêu',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(Colors.white, 'Thực tế'),
                      if (widget.targetWeight != null) ...[
                        const SizedBox(width: 16),
                        _buildLegend(Colors.purpleAccent, 'Mục tiêu'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard('Bắt đầu',
                              '${startWeight.toStringAsFixed(1)} kg')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildStatCard('Hiện tại',
                              '${currentWeight.toStringAsFixed(1)} kg')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildStatCard('Thay đổi',
                              '${change.startsWith('-') ? '' : '+'}$change kg',
                              valueColor: changeColor)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _openWeightHistory(sorted),
                      icon: const Icon(Icons.history, color: Colors.white),
                      label: const Text('Xem lịch sử cân nặng',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                ],
              );
            }

            // ============ KHÔNG CÓ DỮ LIỆU ============
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    _buildTab('1 tháng', 0),
                    _buildTab('6 tháng', 1),
                    _buildTab('Năm', 2),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedTab == 0)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _onNavigateMonth(-1),
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.white70),
                          ),
                          Text(_getRangeLabel(),
                              style: const TextStyle(color: Colors.white70)),
                          IconButton(
                            onPressed: () => _onNavigateMonth(1),
                            icon: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white70),
                          ),
                        ],
                      )
                    else
                      Text(
                        _getRangeLabel(),
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Biểu đồ cân nặng',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: 0.92,
                    child: SizedBox(
                      height: 190,
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.white24, width: 1),
                            bottom: BorderSide(color: Colors.white24, width: 1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Không có dữ liệu cân nặng",
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(Colors.white, 'Thực tế'),
                    if (widget.targetWeight != null) ...[
                      const SizedBox(width: 16),
                      _buildLegend(Colors.purpleAccent, 'Mục tiêu'),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Bắt đầu', '- kg')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('Hiện tại', '- kg')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('Thay đổi', '- kg')),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.history, color: Colors.white),
                    label: const Text('Xem lịch sử cân nặng',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTab(String text, int idx) {
    final selected = idx == _selectedTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(idx),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.purpleAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252836),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) => Row(
        children: [
          Container(width: 24, height: 2, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );

  void _showAddWeightDialog() async {
    final formKey = GlobalKey<FormState>();
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Ghi lại cân nặng'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cân nặng (kg)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nhập cân nặng!';
                      }
                      final n = double.tryParse(val);
                      if (n == null || n <= 0) return 'Số không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Ngày:', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365 * 5)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        child:
                            Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final double kg = double.parse(weightController.text);
                    Navigator.of(context).pop(); // Đóng dialog nhập
                    // Gọi Cubit, đánh dấu đang chờ thành công
                    setState(() {
                      _pendingAddWeight = true;
                      _lastLoggedDate = selectedDate;
                    });
                    await context.read<WeightLogCubit>().addWeightLog(
                          weightKg: kg,
                          date: selectedDate,
                          rangeStart: _rangeStart,
                          rangeEnd: _rangeEnd,
                        );
                  }
                },
                child: const Text('Lưu'),
              )
            ],
          ),
        );
      },
    );
  }
}
