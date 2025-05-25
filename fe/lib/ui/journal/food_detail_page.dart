// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pie_chart/pie_chart.dart';

import '../../blocs/food/food_cubit.dart';
import '../../blocs/food/food_state.dart';
import '../../blocs/log/journal_cubit.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import 'package:nutrition_app/utils/dialog_helper.dart';

class FoodDetailPage extends StatefulWidget {
  final int foodId; // ID của món ăn
  final double initialQuantity; // Lượng khẩu phần ban đầu (gram)
  final bool isEditing; // Có đang ở chế độ chỉnh sửa log hay không
  final DateTime? timestamp; // Thời điểm log món ăn (chỉ cần nếu là edit)

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
  late double _quantity; // Biến lưu lượng khẩu phần hiện tại
  bool _showMore = false; // Cờ để ẩn/hiện dinh dưỡng chi tiết
  late final TextEditingController
      _controller; // Điều khiển TextField nhập khẩu phần

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _controller = TextEditingController(text: _quantity.toStringAsFixed(1));

    // Nếu chưa load hoặc foodId khác thì gọi load lại
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

  /// Tính toán lại dinh dưỡng dựa trên khẩu phần hiện tại
  Map<String, dynamic> _calculateNutrition(food, double quantity) {
    final factor = quantity / food.servingSize;
    final pro = food.protein * factor;
    final carb = food.carbs * factor;
    final fat = food.fat * factor;
    final cal = (food.calories * factor).round();
    final total = pro + carb + fat;
    return {
      'cal': cal,
      'pro': pro,
      'carb': carb,
      'fat': fat,
      'proPct': total == 0 ? 0 : ((pro / total) * 100).round(),
      'carbPct': total == 0 ? 0 : ((carb / total) * 100).round(),
      'fatPct': total == 0 ? 0 : ((fat / total) * 100).round(),
    };
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
            final nutri = _calculateNutrition(food, _quantity);

            return Stack(
              children: [
                // Nội dung chính: ảnh, thông tin, macro chart, bảng dinh dưỡng
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
                  children: [
                    // Ảnh món ăn
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: food.imageUrl != null
                          ? Image.network(food.imageUrl!,
                              height: 160, fit: BoxFit.cover)
                          : Image.asset('assets/images/suon-nuong-mat-ong.png',
                              height: 160, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),

                    // Tên món ăn
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

                    // Vòng tròn calories + tỷ lệ macro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              dataMap: {
                                'Đạm': nutri['pro'],
                                'Carb': nutri['carb'],
                                'Béo': nutri['fat']
                              },
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
                                Text('${nutri['cal']}',
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
                        _macroColumn(
                            nutri['proPct'],
                            nutri['pro'],
                            'assets/icons/proteins.png',
                            'Chất đạm',
                            Colors.red),
                        _macroColumn(nutri['carbPct'], nutri['carb'],
                            'assets/icons/carb.png', 'Đường bột', Colors.blue),
                        _macroColumn(nutri['fatPct'], nutri['fat'],
                            'assets/icons/fat.png', 'Chất béo', Colors.orange),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Cảnh báo món custom chưa xác nhận
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
                    _nutrientRow('Năng lượng', '${nutri['cal']} kcal'),
                    _nutrientRow('Đường bột (carb)',
                        '${nutri['carb'].toStringAsFixed(1)} g'),
                    _nutrientRow('Chất béo (fat)',
                        '${nutri['fat'].toStringAsFixed(1)} g'),
                    _nutrientRow('Chất đạm (protein)',
                        '${nutri['pro'].toStringAsFixed(1)} g'),

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

                // Bottom bar nhập khẩu phần và nút Thêm/Cập nhật
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

  /// Widget thanh đáy màn hình chứa TextField nhập gram + nút hành động
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
                // Nếu đang chỉnh sửa, chỉ cần pop quantity về lại JournalPage để xử lý tiếp
                if (!context.mounted) return;
                showSuccessDialog(context, 'Đã cập nhật khẩu phần!');
                await Future.delayed(const Duration(seconds: 1));
                if (!context.mounted) return;
                Navigator.pop(context, _quantity);
              } else {
                // Nếu là thêm mới món ăn
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
                context.read<MetricsCubit>().loadMetricsForDate(timestamp);
                showSuccessDialog(context, 'Đã thêm món ăn!');
                await Future.delayed(const Duration(seconds: 1));
                if (!context.mounted) return;
                Navigator.pop(context, true);
              }
            },
            child: Text(widget.isEditing ? 'Cập nhật' : 'Thêm vào'),
          ),
        ],
      ),
    );
  }

  /// Cột hiển thị phần trăm + số gram + icon macro
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

  /// Từng dòng thể hiện thành phần dinh dưỡng (label + value)
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
