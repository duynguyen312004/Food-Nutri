import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/food/food_cubit.dart';
import '../../blocs/recent_log/recent_meals_cubit.dart';
import '../../blocs/recent_log/recent_meals_state.dart';
import '../../blocs/log/journal_cubit.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import 'food_detail_page.dart';

/// Trang thêm món ăn vào nhật ký tại một khung giờ cụ thể trong ngày.
/// Bao gồm các tab như: Gần đây, Tạo bởi tôi, Yêu thích, Thực đơn.
class AddMealPage extends StatefulWidget {
  final DateTime selectedDate;
  final int selectedHour;

  const AddMealPage({
    super.key,
    required this.selectedDate,
    required this.selectedHour,
  });

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  int _selectedTabIndex = 0;
  final tabs = ['Gần đây', 'Tạo bởi tôi', 'Yêu thích', 'Thực đơn'];

  @override
  void initState() {
    super.initState();
    final state = context.read<RecentMealsCubit>().state;
    if (state is! RecentMealsLoaded) {
      context.read<RecentMealsCubit>().loadRecentMeals(widget.selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeRange =
        '${widget.selectedHour.toString().padLeft(2, '0')}:00 - ${(widget.selectedHour + 1).toString().padLeft(2, '0')}:00';

    return Scaffold(
      appBar: AppBar(
        title: Text(timeRange),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          const SizedBox(height: 8),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  /// Thanh tìm kiếm món ăn
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Tìm món ăn...',
            hintStyle: TextStyle(color: Colors.white54),
            prefixIcon: Icon(Icons.search, color: Colors.white60),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// Thanh tab chuyển giữa các chế độ xem món ăn
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (index) {
          final selected = index == _selectedTabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Column(
                children: [
                  Text(
                    tabs[index],
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white60,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (selected)
                    Container(
                      height: 2,
                      width: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Các tùy chọn thêm món nhanh bằng mã vạch, camera, giọng nói
  Widget _buildAddOptionsRow() {
    final options = [
      {'label': 'Mã vạch', 'image': 'assets/icons/qr_scan.png'},
      {'label': 'Scan ảnh', 'image': 'assets/icons/camera.png'},
      {'label': 'Voice log', 'image': 'assets/icons/mic.png'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options.map((opt) {
          return Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(opt['image']!, width: 32, height: 32),
                const SizedBox(height: 6),
                Text(opt['label']!,
                    style: const TextStyle(fontSize: 12, color: Colors.white))
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Nội dung theo từng tab, hiện tại chỉ xử lý tab Gần đây
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return BlocBuilder<RecentMealsCubit, RecentMealsState>(
          builder: (context, state) {
            if (state is RecentMealsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is RecentMealsError) {
              return Center(child: Text(state.message));
            } else if (state is RecentMealsLoaded) {
              final meals = state.meals;
              return ListView.builder(
                itemCount: meals.length + 1,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  if (index == 0) return _buildAddOptionsRow();
                  final meal = meals[index - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: MealCard(
                      name: meal.name,
                      quantity: meal.quantity,
                      unit: meal.unit,
                      calories: meal.calories.toInt(),
                      protein: meal.protein,
                      carbs: meal.carbs,
                      fat: meal.fat,
                      imagePath: meal.imageUrl ??
                          'assets/images/suon-nuong-mat-ong.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MultiBlocProvider(
                              providers: [
                                BlocProvider.value(
                                    value: context.read<FoodCubit>()),
                                BlocProvider.value(
                                    value: context.read<JournalCubit>()),
                                BlocProvider.value(
                                    value: context.read<MetricsCubit>()),
                              ],
                              child: FoodDetailPage(
                                foodId: meal.foodItemId,
                                initialQuantity: meal.quantity,
                                timestamp: DateTime(
                                  widget.selectedDate.year,
                                  widget.selectedDate.month,
                                  widget.selectedDate.day,
                                  widget.selectedHour,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }
            return const SizedBox();
          },
        );
      default:
        return const Center(
          child: Text('Tính năng đang phát triển...',
              style: TextStyle(color: Colors.white70)),
        );
    }
  }
}

/// Thẻ hiển thị món ăn với tên, macros và hình ảnh
class MealCard extends StatelessWidget {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String imagePath;
  final double quantity;
  final String unit;
  final VoidCallback? onTap;

  const MealCard({
    super.key,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.imagePath,
    required this.quantity,
    required this.unit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF2B2B3C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(imagePath,
                width: 48, height: 48, fit: BoxFit.cover),
          ),
          title: Text(
            '$name (${unit == "g" ? quantity.toStringAsFixed(1) : quantity.toStringAsFixed(0)}$unit)',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _buildMacroIcon('assets/icons/kcal.png', '$calories kcal'),
                const SizedBox(width: 8),
                _buildMacroIcon('assets/icons/proteins.png', '${protein}g'),
                const SizedBox(width: 8),
                _buildMacroIcon('assets/icons/carb.png', '${carbs}g'),
                const SizedBox(width: 8),
                _buildMacroIcon('assets/icons/fat.png', '${fat}g'),
              ],
            ),
          ),
          trailing: const Icon(Icons.add, color: Colors.white),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildMacroIcon(String assetPath, String value) {
    return Row(
      children: [
        Image.asset(assetPath, width: 12, height: 12),
        const SizedBox(width: 2),
        Text(value,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
