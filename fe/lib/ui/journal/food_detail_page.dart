import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pie_chart/pie_chart.dart';

import '../../blocs/food/food_cubit.dart';
import '../../blocs/food/food_state.dart';
import '../../blocs/log/journal_cubit.dart';
import '../../blocs/metrics/metrics_cubit.dart';

class FoodDetailPage extends StatefulWidget {
  final int foodId;
  final double initialQuantity;
  final bool isEditing;
  final DateTime? timestamp;

  const FoodDetailPage({
    super.key,
    required this.foodId,
    required this.initialQuantity,
    this.isEditing = false,
    this.timestamp,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late double _quantity;
  bool _showMore = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _controller = TextEditingController(text: _quantity.toStringAsFixed(1));
    final state = context.read<FoodCubit>().state;
    if (state is! FoodLoaded || state.food.foodItemId != widget.foodId) {
      context.read<FoodCubit>().loadFoodDetail(widget.foodId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Chi tiết món ăn'),
        actions: const [Icon(Icons.favorite_border)],
        centerTitle: true,
      ),
      body: BlocBuilder<FoodCubit, FoodState>(
        builder: (context, state) {
          if (state is FoodLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FoodLoaded) {
            final food = state.food;
            final factor = _quantity / food.servingSize;

            final cal = (food.calories * factor).round();
            final pro = (food.protein * factor);
            final carb = (food.carbs * factor);
            final fat = (food.fat * factor);

            final total = pro + carb + fat;
            final proPct = ((pro / total) * 100).round();
            final carbPct = ((carb / total) * 100).round();
            final fatPct = ((fat / total) * 100).round();

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: food.imageUrl != null
                          ? Image.network(food.imageUrl!,
                              height: 160, fit: BoxFit.cover)
                          : Image.asset('assets/images/suon-nuong-mat-ong.png',
                              height: 160, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        food.name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              dataMap: {'Đạm': pro, 'Carb': carb, 'Béo': fat},
                              colorList: const [
                                Colors.red,
                                Colors.blue,
                                Colors.orange
                              ],
                              chartRadius: 60,
                              chartType: ChartType.ring,
                              ringStrokeWidth: 10,
                              baseChartColor: Colors.grey.shade800,
                              legendOptions:
                                  const LegendOptions(showLegends: false),
                              chartValuesOptions: const ChartValuesOptions(
                                  showChartValues: false),
                            ),
                            Column(
                              children: [
                                Text('$cal',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const Text('kcal',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12))
                              ],
                            )
                          ],
                        ),
                        _macroColumn(proPct, pro, 'assets/icons/proteins.png',
                            'Chất đạm', Colors.red),
                        _macroColumn(carbPct, carb, 'assets/icons/carb.png',
                            'Đường bột', Colors.blue),
                        _macroColumn(fatPct, fat, 'assets/icons/fat.png',
                            'Chất béo', Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (food.isCustom == true)
                      const Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.amber, size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Do người dùng cung cấp, chưa được xác nhận',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text('Giá trị dinh dưỡng',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _nutrientRow('Năng lượng', '$cal kcal'),
                    _nutrientRow(
                        'Đường bột (carb)', '${carb.toStringAsFixed(1)} g'),
                    _nutrientRow(
                        'Chất béo (fat)', '${fat.toStringAsFixed(1)} g'),
                    _nutrientRow(
                        'Chất đạm (protein)', '${pro.toStringAsFixed(1)} g'),
                    if (_showMore) ...[
                      const SizedBox(height: 8),
                      _nutrientRow('Chất xơ', '0.5 g'),
                      _nutrientRow('Đường', '1.2 g'),
                      _nutrientRow('Cholesterol', '80 mg'),
                      _nutrientRow('Muối', '1.1 g'),
                      const SizedBox(height: 24),
                      const Text('Nguyên liệu',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(label: Text('Sườn lợn cốt lết, sống')),
                          Chip(label: Text('Củ sả')),
                          Chip(label: Text('Củ hành tím')),
                          Chip(label: Text('Nước cốt chanh xanh')),
                        ],
                      ),
                    ],
                    TextButton(
                      onPressed: () => setState(() => _showMore = !_showMore),
                      child: Text(_showMore ? 'Ẩn bớt' : 'Xem thêm',
                          style: const TextStyle(color: Colors.purpleAccent)),
                    ),
                  ],
                ),
                Positioned(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 0,
                  right: 0,
                  child: _buildBottomBar(context, food),
                ),
              ],
            );
          }
          return const Center(child: Text('Không tìm thấy món ăn'));
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, dynamic food) {
    final unit = food.servingUnit;
    return Container(
      color: const Color(0xFF1E1E2C),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[900],
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixText: unit,
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                final val = double.tryParse(value);
                if (val != null && val > 0) {
                  setState(() => _quantity = val);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (widget.isEditing) {
                Navigator.pop(context, _quantity);
              } else {
                final timestamp = widget.timestamp ?? DateTime.now();
                String getMealName(DateTime time) {
                  final h = time.hour;
                  if (h >= 4 && h < 10) return 'Bữa sáng';
                  if (h >= 10 && h < 14) return 'Bữa trưa';
                  if (h >= 14 && h < 18) return 'Bữa xế';
                  if (h >= 18 && h < 22) return 'Bữa tối';
                  return 'Ăn khuya';
                }

                await context.read<JournalCubit>().addMealLog(
                      timestamp,
                      food: food,
                      quantity: _quantity,
                      mealName: getMealName(timestamp),
                    );
                if (!context.mounted) return;

                // Gọi để cập nhật lại phần header (TDEE, macro, calorie đã nạp...)
                context.read<MetricsCubit>().loadMetricsForDate(timestamp);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã thêm món vào nhật ký'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            child: Text(widget.isEditing ? 'Cập nhật' : 'Thêm vào'),
          ),
        ],
      ),
    );
  }

  Widget _macroColumn(
      int percent, double value, String iconPath, String label, Color color) {
    return Column(
      children: [
        Text('$percent%',
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text('${value.toStringAsFixed(1)} g',
            style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        Row(
          children: [
            Image.asset(iconPath, width: 14, height: 14),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _nutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
