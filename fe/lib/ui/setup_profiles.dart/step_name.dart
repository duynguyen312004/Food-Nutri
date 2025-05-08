// lib/ui/setup_profiles/step_name.dart
import 'package:flutter/material.dart';

class NameStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;

  const NameStep({
    super.key,
    required this.formKey,
    required this.lastNameController,
    required this.firstNameController,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.1), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Họ và tên của bạn?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cá nhân hóa trải nghiệm FoodNutri của bạn bằng cách tạo tài khoản',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          Form(
            key: formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: lastNameController,
                  label: 'Họ',
                  hint: 'Nhập họ của bạn',
                  primaryColor: primary,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: firstNameController,
                  label: 'Tên',
                  hint: 'Nhập tên của bạn',
                  primaryColor: primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color primaryColor,
  }) {
    return TextFormField(
      controller: controller,
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Vui lòng nhập $label'
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
