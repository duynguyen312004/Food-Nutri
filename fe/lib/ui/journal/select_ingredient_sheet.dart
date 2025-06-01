import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/food/food_cubit.dart';
import '../../../blocs/food/food_state.dart';
import '../../../models/food_item_model.dart';
import '../../../models/ingredient_entry.dart';
// Import FastImage widget của bạn
import '../../../widgets/fast_image.dart';

class SelectIngredientSheet extends StatefulWidget {
  const SelectIngredientSheet({super.key});

  @override
  State<SelectIngredientSheet> createState() => _SelectIngredientSheetState();
}

class _SelectIngredientSheetState extends State<SelectIngredientSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<FoodCubit>().searchFoods(query);
    } else {
      context.read<FoodCubit>().clear();
    }
  }

  void _onSelectFood(FoodItem food) async {
    final qtyController = TextEditingController(text: '100');
    final entry = await showDialog<IngredientEntry>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thêm "${food.name}"'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration:
              InputDecoration(labelText: 'Khối lượng (${food.servingUnit})'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text);
              if (qty != null && qty > 0) {
                Navigator.pop(
                  ctx,
                  IngredientEntry(
                    food: food,
                    quantity: qty,
                    unit: food.servingUnit,
                  ),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    // Nếu dialog trả về entry, pop ra khỏi bottom sheet với kết quả đó!
    if (entry != null && mounted) {
      Navigator.pop(context, entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _onSearchChanged(),
            decoration: const InputDecoration(
              hintText: 'Tìm món ăn...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<FoodCubit, FoodState>(
              builder: (context, state) {
                if (state is FoodLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<FoodItem> results = [];
                if (state is FoodListLoaded) {
                  results = state.results;
                }
                if (results.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy món ăn phù hợp.'),
                  );
                }
                return ListView.separated(
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final food = results[i];
                    return ListTile(
                      leading: FastImage(
                        imagePath: food.imageUrl ?? '',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.calories} kcal / ${food.servingSize} ${food.servingUnit}',
                      ),
                      onTap: () => _onSelectFood(food),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
