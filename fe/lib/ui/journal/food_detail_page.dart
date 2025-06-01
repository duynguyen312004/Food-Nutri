import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/food/custom_food_cubit.dart';
import '../../blocs/food/custom_food_state.dart';
import '../../blocs/food/food_cubit.dart';
import '../../blocs/food/food_state.dart';
import '../../blocs/food/recipe_cubit.dart';
import '../../blocs/food/recipe_state.dart';
import '../../blocs/log/journal_cubit.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../utils/dialog_helper.dart';
import '../../blocs/recent_log/recent_meals_cubit.dart';
import '../../widgets/fast_image.dart';
import '../../widgets/macro_pie_chart.dart';
import 'add_custom_food_page.dart';
import 'create_recipe_page.dart';

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
  late DateTime _timestamp;
  bool _showMore = false;
  late final TextEditingController _controller;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _controller = TextEditingController(text: _quantity.toStringAsFixed(1));
    _timestamp = widget.timestamp ?? DateTime.now();

    final state = context.read<FoodCubit>().state;
    if (state is! FoodLoaded || state.food.foodItemId != widget.foodId) {
      context.read<FoodCubit>().loadFoodDetail(widget.foodId);
    }
    // TODO: Load trạng thái favorite từ server/local nếu có
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    // TODO: Gửi favorite lên backend nếu có
  }

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
    return MultiBlocListener(
      listeners: [
        BlocListener<CustomFoodCubit, CustomFoodState>(
          listener: (context, state) async {
            if (state is CustomFoodSuccess) {
              if (!context.mounted) return;
              await showSuccessDialog(context, 'Đã xoá thành công!');
              if (context.mounted) Navigator.pop(context, true);
            } else if (state is CustomFoodError) {
              if (!context.mounted) return;
              final msg = state.message.toLowerCase();
              if (msg.contains('foreignkeyviolation') ||
                  msg.contains('referenced from table') ||
                  msg.contains('cannot_delete_used_food') ||
                  msg.contains('xoá thực phẩm thất bại') ||
                  msg.contains('xoa thuc pham that bai')) {
                await showErrorDialog(
                  context,
                  'Không thể xoá món ăn này vì đã từng được sử dụng trong nhật ký.\n'
                  'Hãy xoá các log/bữa ăn liên quan trước rồi thử lại nhé!',
                );
              } else {
                final displayMsg =
                    msg.replaceFirst(RegExp(r'^exception:\s*'), '');
                await showErrorDialog(context, displayMsg);
              }
            }
          },
        ),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Chi tiết món ăn'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.pinkAccent),
              tooltip: _isFavorite ? "Bỏ yêu thích" : "Thêm vào yêu thích",
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: BlocBuilder<FoodCubit, FoodState>(
          builder: (context, state) {
            if (state is FoodLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FoodLoaded) {
              final food = state.food;
              final nutri = _calculateNutrition(food, _quantity);

              // --- Fix bug dính nguyên liệu cũ ---
              if (food.isRecipe) {
                context
                    .read<RecipeCubit>()
                    .loadRecipeIngredients(food.foodItemId);
              } else {
                context.read<RecipeCubit>().reset();
              }

              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FastImage(
                          imagePath: food.imageUrl ?? '',
                          height: 180,
                          width: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              food.name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (food.isCustom || food.isRecipe)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => food.isRecipe
                                          ? CreateRecipePage(
                                              initialRecipe: food, isEdit: true)
                                          : AddCustomFoodPage(
                                              initialFood: food, isEdit: true),
                                    ),
                                  );
                                  if (result == true && context.mounted) {
                                    context
                                        .read<FoodCubit>()
                                        .loadFoodDetail(food.foodItemId);
                                  }
                                } else if (value == 'delete') {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Xác nhận xoá"),
                                      content: Text(
                                          'Bạn có chắc muốn xoá "${food.name}" không?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text("Huỷ"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: TextButton.styleFrom(
                                              foregroundColor: Colors.red),
                                          child: const Text("Xoá"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && context.mounted) {
                                    await context
                                        .read<CustomFoodCubit>()
                                        .deleteCustomFood(food.foodItemId);
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit,
                                          color: Colors.deepOrange, size: 18),
                                      SizedBox(width: 10),
                                      Text('Sửa thông tin'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          color: Colors.red, size: 18),
                                      SizedBox(width: 10),
                                      Text('Xoá món ăn'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MacroPieChart(
                        calories: nutri['cal'] * 1.0,
                        protein: nutri['pro'],
                        carbs: nutri['carb'],
                        fat: nutri['fat'],
                        showIcon: true,
                      ),
                      const SizedBox(height: 12),
                      if (food.isCustom)
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
                      if (_showMore && food.isRecipe) ...[
                        const SizedBox(height: 24),
                        const Text('Nguyên liệu',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600)),
                        BlocBuilder<RecipeCubit, RecipeState>(
                          builder: (context, state) {
                            if (state is RecipeIngredientsLoaded) {
                              return Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: state.ingredients
                                    .map((e) => Chip(label: Text(e.food.name)))
                                    .toList(),
                              );
                            }
                            return const SizedBox.shrink();
                          },
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
      ),
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
                if (!context.mounted) return;
                await showSuccessDialog(context, 'Đã cập nhật khẩu phần!');
                if (!context.mounted) return;
                Navigator.pop(context, _quantity);
              } else {
                final timestamp = _timestamp;
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
                context
                    .read<RecentMealsCubit>()
                    .loadRecentMeals(widget.timestamp ?? DateTime.now());
                await showSuccessDialog(context, 'Đã thêm món ăn!');
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
}
