import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../blocs/food/custom_food_cubit.dart';
import '../../blocs/food/custom_food_state.dart';
import '../../models/food_item_model.dart';

class AddCustomFoodPage extends StatefulWidget {
  final FoodItem? initialFood;
  final bool isEdit;
  const AddCustomFoodPage({super.key, this.initialFood, this.isEdit = false});

  @override
  State<AddCustomFoodPage> createState() => _AddCustomFoodPageState();
}

class _AddCustomFoodPageState extends State<AddCustomFoodPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;
  String _unit = 'g';
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final food = widget.initialFood;
    _nameController = TextEditingController(text: food?.name ?? '');
    _caloriesController = TextEditingController(
        text: food?.calories != null ? food!.calories.toString() : '');
    _proteinController = TextEditingController(
        text: food?.protein != null ? food!.protein.toString() : '');
    _fatController = TextEditingController(
        text: food?.fat != null ? food!.fat.toString() : '');
    _carbsController = TextEditingController(
        text: food?.carbs != null ? food!.carbs.toString() : '');
    _unit = food?.servingUnit ?? 'g';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final calories = double.tryParse(_caloriesController.text) ?? 0;
      final protein = double.tryParse(_proteinController.text) ?? 0;
      final fat = double.tryParse(_fatController.text) ?? 0;
      final carbs = double.tryParse(_carbsController.text) ?? 0;

      if (widget.isEdit && widget.initialFood != null) {
        context.read<CustomFoodCubit>().updateCustomFood(
              foodItemId: widget.initialFood!.foodItemId,
              name: name,
              unit: _unit,
              calories: calories,
              protein: protein,
              fat: fat,
              carbs: carbs,
              image: _imageFile,
            );
      } else {
        context.read<CustomFoodCubit>().createCustomFood(
              name: name,
              unit: _unit,
              calories: calories,
              protein: protein,
              fat: fat,
              carbs: carbs,
              image: _imageFile,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomFoodCubit, CustomFoodState>(
      listener: (context, state) async {
        if (state is CustomFoodSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEdit
                  ? 'Cập nhật thực phẩm thành công!'
                  : 'Tạo thực phẩm thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          // Chờ 0.8s rồi pop, tránh pop quá nhanh SnackBar không kịp hiện
          await Future.delayed(const Duration(milliseconds: 800));
          if (context.mounted) Navigator.pop(context, true);
        } else if (state is CustomFoodError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(widget.isEdit ? 'Chỉnh sửa thực phẩm' : 'Tạo mới thực phẩm'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _pickImage,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _imagePreview(),
                  ),
                ),
                TextButton(
                  onPressed: _pickImage,
                  child: const Text('+ Tải lên ảnh mới'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: 'Tên thực phẩm *'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bắt buộc nhập tên'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Đơn vị tính',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    DropdownButton<String>(
                      value: _unit,
                      items: const [
                        DropdownMenuItem(value: 'g', child: Text('Gram')),
                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                      ],
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Khối lượng được tính trên 100 gram/ml',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  controller: _caloriesController,
                  label: 'Calories *',
                  suffix: 'cal',
                  required: true,
                ),
                const SizedBox(height: 6),
                _buildNumberField(
                  controller: _proteinController,
                  label: 'Protein',
                  suffix: 'gram',
                ),
                const SizedBox(height: 6),
                _buildNumberField(
                  controller: _fatController,
                  label: 'Fat',
                  suffix: 'gram',
                ),
                const SizedBox(height: 6),
                _buildNumberField(
                  controller: _carbsController,
                  label: 'Carbs',
                  suffix: 'gram',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<CustomFoodCubit, CustomFoodState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is CustomFoodLoading ? null : _submit,
                        child: state is CustomFoodLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(widget.isEdit
                                ? 'Cập nhật thực phẩm'
                                : 'Lưu thực phẩm'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget preview ảnh, fallback icon nếu không có
  Widget _imagePreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child:
            Image.file(_imageFile!, fit: BoxFit.cover, width: 110, height: 110),
      );
    }
    final url = widget.initialFood?.imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          errorWidget: (_, __, ___) =>
              const Icon(Icons.image, size: 48, color: Colors.white24),
          placeholder: (_, __) =>
              const Icon(Icons.image, size: 48, color: Colors.white24),
        ),
      );
    }
    return const Icon(Icons.image, size: 48, color: Colors.white24);
  }

  // Widget nhập số an toàn và validator luôn >= 0
  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if ((required && (value == null || value.trim().isEmpty))) {
          return 'Bắt buộc nhập $label';
        }
        if (value != null && value.trim().isNotEmpty) {
          final v = double.tryParse(value);
          if (v == null) return 'Chỉ nhập số';
          if (v < 0) return 'Giá trị phải >= 0';
        }
        return null;
      },
    );
  }
}
