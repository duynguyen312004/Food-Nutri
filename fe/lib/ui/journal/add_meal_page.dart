import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../blocs/food/custom_food_cubit.dart';
import '../../blocs/food/my_food_cubit.dart';
import '../../blocs/food/my_food_state.dart';
import '../../blocs/food/food_cubit.dart';
import '../../blocs/food/food_state.dart';
import '../../blocs/food/recipe_cubit.dart';
import '../../blocs/recent_log/recent_meals_cubit.dart';
import '../../blocs/recent_log/recent_meals_state.dart';
import '../../blocs/log/journal_cubit.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../services/favorite_service.dart';
import '../../widgets/fast_image.dart';
import 'add_custom_food_page.dart';
import 'create_recipe_page.dart';
import 'food_detail_page.dart';
import 'package:nutrition_app/utils/dialog_helper.dart';

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
  final _searchController = TextEditingController();
  String _searchText = '';
  Timer? _debounceTimer;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    final state = context.read<RecentMealsCubit>().state;
    if (state is! RecentMealsLoaded) {
      context.read<RecentMealsCubit>().loadRecentMeals(widget.selectedDate);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      context.read<FoodCubit>().clear();
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<FoodCubit>().searchFoods(query);
    });
  }

  void _listenVoice() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => setState(() => _isListening = val == "listening"),
        // ignore: avoid_print
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'vi_VN',
          onResult: (val) {
            print('VOICE DEBUG: "${val.recognizedWords}"');
            setState(() {
              _isListening = false;
              _searchController.text = val.recognizedWords;
              _searchText = val.recognizedWords;
            });
            _onSearchChanged(val.recognizedWords);
          },
        );
      } else {
        if (!mounted) return;
        showErrorDialog(
            context, "Không bật được microphone. Kiểm tra quyền truy cập nhé!");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
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
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _buildSearchBar(),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Đang lắng nghe...",
                      style: TextStyle(
                          color: Colors.red[300], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            if (_searchText.isEmpty) ...[
              _buildTabBar(),
              const SizedBox(height: 8),
              Expanded(child: _buildTabContent()),
            ] else
              Expanded(child: _buildSearchResults())
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchText = value.trim());
            _onSearchChanged(value.trim());
          },
          decoration: InputDecoration(
            hintText: 'Tìm món ăn...',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white60),
            suffixIcon: _searchText.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white38),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchText = '');
                      context.read<FoodCubit>().clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (index) {
          final selected = index == _selectedTabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                setState(() => _selectedTabIndex = index);
                if (index == 2) {
                  // Yêu thích
                  final favIds = await FavoriteService.getFavorites();
                  if (mounted) {
                    context.read<FoodCubit>().loadFavoriteFoods(favIds);
                  }
                }
              },
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

  Widget _buildAddOptionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _addOptionItem('Mã vạch', 'assets/icons/qr_scan.png', null),
          _addOptionItem('Scan ảnh', 'assets/icons/camera.png', null),
          _addOptionItem('Voice log', 'assets/icons/mic.png', _listenVoice,
              isListening: _isListening),
        ],
      ),
    );
  }

  Widget _addOptionItem(String label, String icon, VoidCallback? onTap,
      {bool isListening = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: isListening ? Colors.red.withOpacity(0.1) : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: isListening
              ? Border.all(color: Colors.redAccent, width: 2)
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: isListening ? Colors.red : null),
              child: Image.asset(icon,
                  width: 32,
                  height: 32,
                  color: isListening ? Colors.redAccent : null),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isListening ? Colors.redAccent : Colors.white,
                fontWeight: isListening ? FontWeight.bold : FontWeight.normal,
              ),
            )
          ],
        ),
      ),
    );
  }

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
                  return Dismissible(
                    key: ValueKey(meal.foodItemId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      context
                          .read<RecentMealsCubit>()
                          .removeMealFromUI(meal.foodItemId);
                      showDeleteDialog(
                          context, 'Đã ẩn khỏi gần đây: ${meal.name}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: MealCard(
                        name: meal.name,
                        quantity: meal.quantity,
                        unit: meal.unit,
                        calories: meal.calories.toInt(),
                        protein: meal.protein,
                        carbs: meal.carbs,
                        fat: meal.fat,
                        imagePath: meal.imageUrl ?? 'assets/images/food.jpg',
                        onTap: () async {
                          final result = await Navigator.push(
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
                                  BlocProvider(create: (_) => RecipeCubit()),
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
                          if (result == true && context.mounted) {
                            await context
                                .read<RecentMealsCubit>()
                                .loadRecentMeals(widget.selectedDate);
                            setState(() {
                              _searchController.clear();
                              _searchText = '';
                              _selectedTabIndex = 0;
                            });
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox();
          },
        );

      case 1:
        return BlocBuilder<MyFoodsCubit, MyFoodsState>(
          builder: (context, state) {
            Widget addRow = Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => RecipeCubit(),
                              child: const CreateRecipePage(),
                            ),
                          ),
                        );
                        if (result == true && context.mounted) {
                          context.read<MyFoodsCubit>().loadMyFoods();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/icons/recipe_book.png',
                                width: 36, height: 36),
                            const SizedBox(height: 8),
                            Text(
                              'Tạo mới món ăn',
                              style: TextStyle(
                                color: Colors.green[400],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => CustomFoodCubit(),
                              child: const AddCustomFoodPage(),
                            ),
                          ),
                        );
                        if (result == true && context.mounted) {
                          context.read<MyFoodsCubit>().loadMyFoods();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/icons/add_food.png',
                                width: 36, height: 36),
                            const SizedBox(height: 8),
                            const Text(
                              'Tạo mới thực phẩm',
                              style: TextStyle(
                                color: Colors.deepOrangeAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            Widget foodList;
            if (state is MyFoodsLoading) {
              foodList = const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (state is MyFoodsLoaded && state.foods.isNotEmpty) {
              foodList = ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                itemCount: state.foods.length,
                itemBuilder: (context, index) {
                  final food = state.foods[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: MealCard(
                      name: food.name,
                      quantity: food.servingSize,
                      unit: food.servingUnit,
                      calories: food.calories.toInt(),
                      protein: food.protein,
                      carbs: food.carbs,
                      fat: food.fat,
                      imagePath: food.imageUrl ?? 'assets/images/food.jpg',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FoodDetailPage(
                              foodId: food.foodItemId,
                              initialQuantity: food.servingSize,
                              isEditing: false,
                              timestamp: DateTime(
                                widget.selectedDate.year,
                                widget.selectedDate.month,
                                widget.selectedDate.day,
                                widget.selectedHour,
                              ),
                            ),
                          ),
                        );
                        if (result == true && context.mounted) {
                          context.read<MyFoodsCubit>().loadMyFoods();
                        }
                      },
                    ),
                  );
                },
              );
            } else if (state is MyFoodsLoaded && state.foods.isEmpty) {
              foodList = Padding(
                padding: const EdgeInsets.only(top: 40),
                child: _buildEmptyStateMyFoods(),
              );
            } else if (state is MyFoodsError) {
              foodList = Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(child: Text(state.message)),
              );
            } else {
              foodList = const SizedBox();
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  addRow,
                  foodList,
                ],
              ),
            );
          },
        );
      case 2:
        return FutureBuilder<List<int>>(
          future: FavoriteService.getFavorites(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final favIds = snapshot.data!;
            if (favIds.isEmpty) {
              return const Center(
                  child: Text('Chưa có món ăn yêu thích nào!',
                      style: TextStyle(color: Colors.white70)));
            }

            return BlocBuilder<FoodCubit, FoodState>(
              builder: (context, state) {
                if (state is FoodLoading || state is FoodInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is FoodListLoaded) {
                  final favFoods = state.results;
                  if (favFoods.isEmpty) {
                    return const Center(
                        child: Text('Chưa có món ăn yêu thích nào!',
                            style: TextStyle(color: Colors.white70)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: favFoods.length,
                    itemBuilder: (context, index) {
                      final food = favFoods[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: MealCard(
                          name: food.name,
                          quantity: food.servingSize,
                          unit: food.servingUnit,
                          calories: food.calories.toInt(),
                          protein: food.protein,
                          carbs: food.carbs,
                          fat: food.fat,
                          imagePath: food.imageUrl ?? 'assets/images/food.jpg',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FoodDetailPage(
                                  foodId: food.foodItemId,
                                  initialQuantity: food.servingSize,
                                  timestamp: DateTime(
                                    widget.selectedDate.year,
                                    widget.selectedDate.month,
                                    widget.selectedDate.day,
                                    widget.selectedHour,
                                  ),
                                ),
                              ),
                            );
                            // 👇 CHỈ RELOAD KHI result == true (tức là có đổi favorite)
                            if (result == true) {
                              final favIds =
                                  await FavoriteService.getFavorites();
                              if (context.mounted) {
                                context
                                    .read<FoodCubit>()
                                    .loadFavoriteFoods(favIds);
                                setState(() {}); // Đảm bảo rebuild lại tab
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                }
                if (state is FoodError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox();
              },
            );
          },
        );

      default:
        return const Center(
          child: Text('Tính năng đang phát triển...',
              style: TextStyle(color: Colors.white70)),
        );
    }
  }

  Widget _buildSearchResults() {
    return BlocBuilder<FoodCubit, FoodState>(
      builder: (context, state) {
        if (state is FoodLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FoodListLoaded) {
          final foods = state.results;
          if (foods.isEmpty) {
            return const Center(child: Text("Không tìm thấy món ăn nào!"));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: foods.length,
            itemBuilder: (context, index) {
              final food = foods[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: MealCard(
                  name: food.name,
                  quantity: food.servingSize,
                  unit: food.servingUnit,
                  calories: food.calories.toInt(),
                  protein: food.protein,
                  carbs: food.carbs,
                  fat: food.fat,
                  imagePath: food.imageUrl ?? 'assets/images/food.jpg',
                  onTap: () async {
                    final result = await Navigator.push(
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
                            BlocProvider(create: (_) => RecipeCubit()),
                          ],
                          child: FoodDetailPage(
                            foodId: food.foodItemId,
                            initialQuantity: food.servingSize,
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
                    if (result == true) {
                      _searchController.clear();
                      setState(() {
                        _searchText = '';
                        _selectedTabIndex = 0;
                      });
                      if (!context.mounted) return;
                      await context
                          .read<RecentMealsCubit>()
                          .loadRecentMeals(widget.selectedDate);
                    }
                  },
                ),
              );
            },
          );
        } else if (state is FoodError) {
          return Center(child: Text('Lỗi: ${state.message}'));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildEmptyStateMyFoods() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Bạn chưa có món nào tự tạo.",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

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
              child: FastImage(imagePath: imagePath, width: 48, height: 48)),
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
                _buildMacroIcon('assets/icons/proteins.png',
                    '${protein.toStringAsFixed(1)}g'),
                const SizedBox(width: 8),
                _buildMacroIcon(
                    'assets/icons/carb.png', '${carbs.toStringAsFixed(1)}g'),
                const SizedBox(width: 8),
                _buildMacroIcon(
                    'assets/icons/fat.png', '${fat.toStringAsFixed(1)}g'),
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
