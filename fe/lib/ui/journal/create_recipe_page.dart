import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../blocs/food/recipe_cubit.dart';
import '../../blocs/food/recipe_state.dart';
import '../../models/food_item_model.dart';
import '../../models/ingredient_entry.dart';
import '../../utils/dialog_helper.dart';
import 'select_ingredient_sheet.dart';
import '../../widgets/macro_pie_chart.dart';
import '../../widgets/pretty_image.dart'; // dùng PrettyImage cho ảnh đẹp hơn

class CreateRecipePage extends StatefulWidget {
  final FoodItem? initialRecipe;
  final bool isEdit;

  const CreateRecipePage({super.key, this.initialRecipe, this.isEdit = false});

  @override
  State<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController(text: '100');
  final ScrollController _scrollController = ScrollController();
  String _unit = 'g';
  final List<IngredientEntry> _ingredients = [];
  File? _imageFile;
  bool _isChanged = false; // <--- NEW

  @override
  void initState() {
    super.initState();
    final recipe = widget.initialRecipe;
    _nameController.text = recipe?.name ?? '';
    _sizeController.text = recipe?.servingSize.toString() ?? '100';
    _unit = recipe?.servingUnit ?? 'g';

    if (widget.isEdit && recipe != null) {
      context.read<RecipeCubit>().loadRecipeIngredients(recipe.foodItemId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _removeImage() {
    setState(() => _imageFile = null);
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return GestureDetector(
        onLongPress: _removeImage,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _imageFile!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 170,
          ),
        ),
      );
    }
    final url = widget.initialRecipe?.imageUrl ?? '';
    if (widget.isEdit && url.isNotEmpty) {
      return GestureDetector(
        onTap: _pickImage,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PrettyImage(
            imagePath: url,
            width: double.infinity,
            height: 170,
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: const Center(
          child:
              Text('Chọn ảnh món ăn', style: TextStyle(color: Colors.black54)),
        ),
      ),
    );
  }

  Future<void> _addIngredient() async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<IngredientEntry>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.9,
        child: SelectIngredientSheet(),
      ),
    );
    if (result != null) {
      final alreadyExists =
          _ingredients.any((e) => e.food.foodItemId == result.food.foodItemId);
      if (!alreadyExists) {
        setState(() => _ingredients.add(result));
        await Future.delayed(const Duration(milliseconds: 200));
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã thêm: ${result.food.name}')),
          );
        }
      } else {
        if (!mounted) return;
        showErrorDialog(context, 'Nguyên liệu đã có trong danh sách!');
      }
    }
  }

  void _submitRecipe() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_ingredients.isEmpty) {
      showErrorDialog(context, 'Vui lòng thêm ít nhất 1 nguyên liệu');
      return;
    }

    if (widget.isEdit && widget.initialRecipe != null) {
      context.read<RecipeCubit>().updateRecipe(
            foodItemId: widget.initialRecipe!.foodItemId,
            name: _nameController.text.trim(),
            servingSize: double.parse(_sizeController.text),
            unit: _unit,
            ingredients: _ingredients.map((e) => e.toJson()).toList(),
            image: _imageFile,
          );
    } else {
      context.read<RecipeCubit>().createRecipe(
            name: _nameController.text.trim(),
            servingSize: double.parse(_sizeController.text),
            unit: _unit,
            ingredients: _ingredients.map((e) => e.toJson()).toList(),
            image: _imageFile,
          );
    }
  }

  double get _totalCalories =>
      _ingredients.fold(0.0, (sum, e) => sum + e.totalCalories);
  double get _totalProtein =>
      _ingredients.fold(0.0, (sum, e) => sum + e.totalProtein);
  double get _totalCarbs =>
      _ingredients.fold(0.0, (sum, e) => sum + e.totalCarbs);
  double get _totalFat => _ingredients.fold(0.0, (sum, e) => sum + e.totalFat);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Chặn pop mặc định để mình xử lý thủ công
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context, _isChanged);
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(
                widget.isEdit ? 'Chỉnh sửa công thức' : 'Tạo công thức mới'),
            centerTitle: true,
          ),
          body: BlocConsumer<RecipeCubit, RecipeState>(
            listener: (context, state) async {
              if (state is RecipeSuccess) {
                setState(() => _isChanged = true); // <--- Đánh dấu đã thay đổi!
                await showSuccessDialog(
                    context,
                    widget.isEdit
                        ? 'Cập nhật thành công'
                        : 'Tạo món ăn thành công');
                if (context.mounted) Navigator.pop(context, true);
              } else if (state is RecipeError) {
                showErrorDialog(context, state.message);
              } else if (state is RecipeIngredientsLoaded) {
                setState(() {
                  _ingredients.clear();
                  _ingredients.addAll(state.ingredients);
                });
              }
            },
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      _buildImagePreview(),
                      if (_imageFile != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 8),
                          child: Center(
                            child: Text(
                              "Giữ để xoá ảnh",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_ingredients.isNotEmpty) ...[
                        MacroPieChart(
                          calories: _totalCalories,
                          protein: _totalProtein,
                          carbs: _totalCarbs,
                          fat: _totalFat,
                          showIcon: true,
                        ),
                        const SizedBox(height: 18),
                      ],
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Tên món ăn *'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên món ăn';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sizeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Khẩu phần *'),
                              validator: (value) {
                                final v = double.tryParse(value ?? '');
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nhập khẩu phần';
                                }
                                if (v == null || v <= 0) return 'Khẩu phần > 0';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 68,
                            child: DropdownButtonFormField<String>(
                              value: _unit,
                              isDense: true,
                              decoration: const InputDecoration(
                                labelText: '',
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 8),
                                border: OutlineInputBorder(),
                              ),
                              items: ['g', 'ml']
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (val) => setState(() => _unit = val!),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Nguyên liệu (${_ingredients.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      if (_ingredients.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                              child: Text(
                                  'Chưa có nguyên liệu nào. Bấm nút dưới để thêm!',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ))),
                        ),
                      ..._ingredients.map((e) => ListTile(
                            key: ValueKey(e.food.foodItemId),
                            title: Text(e.food.name),
                            subtitle: Text('${e.quantity} ${e.unit}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() => _ingredients.removeWhere(
                                    (entry) =>
                                        entry.food.foodItemId ==
                                        e.food.foodItemId));
                              },
                            ),
                          )),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed:
                            state is RecipeLoading ? null : _addIngredient,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm nguyên liệu'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed:
                            state is RecipeLoading ? null : _submitRecipe,
                        child: state is RecipeLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(widget.isEdit
                                ? 'Cập nhật món ăn'
                                : 'Tạo món ăn'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
