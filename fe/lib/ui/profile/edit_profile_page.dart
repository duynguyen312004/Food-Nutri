import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nutrition_app/blocs/metrics/metrics_cubit.dart';
import '../../blocs/metrics/metrics_state.dart';
import '../../blocs/user/user_data_cubit.dart';
import '../../models/user_model.dart';
import '../../utils/dialog_helper.dart';
import '../../widgets/bmi_bar.dart';
import '../../widgets/bmi_category_table.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel profile;
  final Map<String, dynamic>? metrics; // Truyền thêm metrics động

  const EditProfilePage({super.key, required this.profile, this.metrics});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController =
      TextEditingController(); // Tên
  final TextEditingController _lastNameController =
      TextEditingController(); // Họ
  final TextEditingController _heightController = TextEditingController();
  String _gender = '';
  DateTime _birthDate = DateTime(2000, 1, 1);
  bool _isDirty = false;
  bool _isLoading = false;
  Map<String, dynamic>? _metrics; // Metrics động local

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _firstNameController.text = p.firstName ?? ''; // Tên
    _lastNameController.text = p.lastName ?? ''; // Họ
    _heightController.text = (p.heightCm != null && p.heightCm! > 0)
        ? p.heightCm!.toStringAsFixed(p.heightCm! % 1 == 0 ? 0 : 1)
        : '';
    _firstNameController.addListener(_onChanged);
    _lastNameController.addListener(_onChanged);
    _heightController.addListener(_onChanged);

    _gender = p.gender ?? '';
    _birthDate = p.dateOfBirth ?? DateTime(2000, 1, 1);
    _metrics = widget.metrics;
  }

  void _onChanged() {
    if (!_isDirty) setState(() => _isDirty = true);
    // Không cần gọi reload metrics BE cho cân nặng lý tưởng local
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.deepPurpleAccent,
            surface: Color(0xFF1A1A2E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
        _isDirty = true;
      });
    }
  }

  Future<void> _selectGender() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: const Color(0xFF252836),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chọn giới tính',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        children: [
          _genderOption('Nam'),
          _genderOption('Nữ'),
        ],
      ),
    );
    if (selected != null && selected != _gender) {
      setState(() {
        _gender = selected;
        _isDirty = true;
      });
    }
  }

  Widget _genderOption(String value) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  _gender == value ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (_gender == value)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child:
                  Icon(Icons.check, color: Colors.deepPurpleAccent, size: 18),
            ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate() || !_isDirty || _gender.isEmpty) {
      showErrorDialog(context, 'Vui lòng nhập đầy đủ thông tin!');
      return;
    }
    setState(() => _isLoading = true);

    final updateData = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'gender': _gender,
      'date_of_birth': DateFormat('yyyy-MM-dd').format(_birthDate),
      'height_cm': double.tryParse(_heightController.text),
    };

    try {
      await context.read<UserDataCubit>().updateProfile(updateData);
      if (!mounted) return;

      await context.read<UserDataCubit>().loadUserData();
      if (!mounted) return;

      await context.read<MetricsCubit>().loadMetricsForDate(DateTime.now());
      if (!mounted) return;
      final metricsCubit = context.read<MetricsCubit>();
      if (metricsCubit.state is MetricsLoaded) {
        setState(() {
          _metrics = (metricsCubit.state as MetricsLoaded).metrics;
        });
      }

      setState(() {
        _isDirty = false;
        _isLoading = false;
      });

      if (mounted) {
        showSuccessDialog(context, 'Đã lưu thông tin!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      showErrorDialog(context, 'Có lỗi xảy ra khi lưu thông tin.\n$e');
    }
  }

  // ==== CÔNG THỨC TÍNH CÂN NẶNG LÝ TƯỞNG LOCAL ====
  double calculateIdealWeight({required double heightCm}) {
    const double bmiIdeal = 22; // WHO BMI chuẩn
    final heightM = heightCm / 100;
    return bmiIdeal * heightM * heightM;
  }

  double? _calcIdealWeight() {
    final h = double.tryParse(_heightController.text);
    if (h != null && h > 0) {
      return calculateIdealWeight(heightCm: h);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics ?? {};
    final bmi = (metrics['bmi'] as num?)?.toDouble() ?? 0.0;
    final bmiCategory = _bmiCategoryText(bmi);
    final bmr = (metrics['bmr'] as num?)?.toDouble() ?? 0.0;
    final tdee = (metrics['tdee'] as num?)?.toDouble() ?? 0.0;
    final targetCaloriesPerDay =
        (metrics['target_calories'] as num?)?.toDouble() ?? 0.0;
    final targetCaloriesPerWeek = targetCaloriesPerDay * 7;

    // ==== CÂN NẶNG LÝ TƯỞNG LOCAL ====
    final idealWeightLocal = _calcIdealWeight();
    final idealWeightStr = idealWeightLocal != null
        ? "${idealWeightLocal.toStringAsFixed(1)} kg"
        : "--";

    return PopScope(
      canPop: !_isDirty,
      onPopInvoked: (didPop) async {
        if (didPop || !_isDirty) return;
        bool confirm = await confirmDialog(
          context: context,
          title: "Huỷ thay đổi?",
          message:
              "Bạn có chắc muốn rời khỏi trang? Thông tin đã chỉnh sửa sẽ không được lưu.",
          cancelText: "Ở lại",
          confirmText: "Rời đi",
          confirmColor: Colors.red,
        );
        if (confirm) {
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF181829),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: const BackButton(color: Colors.white),
          title: const Text(
            'Hồ sơ cá nhân',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: (_isDirty &&
                      !_isLoading &&
                      _formKey.currentState?.validate() == true)
                  ? _onSave
                  : null,
              style: TextButton.styleFrom(
                foregroundColor:
                    _isDirty ? Colors.deepPurpleAccent : Colors.white24,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // ==== Thông tin cá nhân ====
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF22223B),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 22, top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin cá nhân',
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _profileRow(
                        label: 'Họ',
                        child: Expanded(
                          child: TextFormField(
                            controller: _lastNameController, // Họ
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Họ',
                              hintStyle: TextStyle(color: Colors.white24),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Nhập họ' : null,
                          ),
                        ),
                      ),
                      _sectionDivider(),
                      _profileRow(
                        label: 'Tên',
                        child: Expanded(
                          child: TextFormField(
                            controller: _firstNameController, // Tên
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Tên',
                              hintStyle: TextStyle(color: Colors.white24),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Nhập tên' : null,
                          ),
                        ),
                      ),
                      _sectionDivider(),
                      _profileRow(
                        label: 'Giới tính',
                        child: GestureDetector(
                          onTap: _selectGender,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(_gender,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.white38),
                            ],
                          ),
                        ),
                      ),
                      _sectionDivider(),
                      _profileRow(
                        label: 'Ngày sinh',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                                DateFormat('dd / MM / yyyy').format(_birthDate),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: const Icon(Icons.calendar_today,
                                  color: Colors.white38, size: 20),
                              onPressed: _pickDate,
                            )
                          ],
                        ),
                      ),
                      _sectionDivider(),
                      _profileRow(
                        label: 'Chiều cao',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              child: TextFormField(
                                controller: _heightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(bottom: 4),
                                ),
                                validator: (v) {
                                  final h = double.tryParse(v ?? '');
                                  if (h == null || h <= 0) {
                                    return 'Chiều cao không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 2.5),
                              child: Text('Cm',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0)),
                            ),
                          ],
                        ),
                      ),
                      _sectionDivider(),
                      _profileRow(
                        label: 'Email',
                        child: Text(widget.profile.email ?? '',
                            style: const TextStyle(
                                color: Colors.white38,
                                fontWeight: FontWeight.w500,
                                fontSize: 15)),
                      ),
                    ],
                  ),
                ),
                // ==== KHU VỰC METRICS (BMI/BMR/TDEE...) ====
                if (metrics.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF29294D),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    margin: const EdgeInsets.only(bottom: 22),
                    child: _metricsSection(
                      targetCaloriesPerDay: targetCaloriesPerDay,
                      targetCaloriesPerWeek: targetCaloriesPerWeek,
                      bmr: bmr,
                      tdee: tdee,
                      bmi: bmi,
                      bmiCategory: bmiCategory,
                      idealWeight: idealWeightStr, // SỬ DỤNG CÂN NẶNG LOCAL!
                      bmiMin: 15,
                      bmiMax: 35,
                    ),
                  ),
                if (metrics.isNotEmpty)
                  BmiCategoryTable(bmi: bmi), // bảng BMI động
                if (metrics.isNotEmpty) const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                )),
          ),
          child,
        ],
      ),
    );
  }

  Widget _sectionDivider() => const Divider(
        height: 1,
        thickness: 0.6,
        color: Colors.white12,
      );

  Widget _metricsSection({
    required double targetCaloriesPerDay,
    required double targetCaloriesPerWeek,
    required double bmr,
    required double tdee,
    required double bmi,
    required String bmiCategory,
    required String idealWeight,
    required double bmiMin,
    required double bmiMax,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                'Lượng calo mục tiêu bạn cần nạp',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
              SizedBox(width: 6),
              Icon(Icons.info_outline, color: Colors.white30, size: 18)
            ],
          ),
        ),
        const Row(
          children: [
            Text('🔥🔥🔥 ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                'Chúng tôi ước tính được lượng calo cần thiết cho hoạt động mỗi ngày',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent.withOpacity(0.65),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _caloBox(
                value: targetCaloriesPerDay,
                label: 'calo/ngày',
                isRight: false,
              ),
              _caloBox(
                value: targetCaloriesPerWeek,
                label: 'calo/tuần',
                isRight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF232338),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _infoRow('Tỷ lệ chuyển hoá cơ bản (BMR)', bmr, 'calo/ngày'),
              const Divider(color: Colors.white10),
              _infoRow('Tổng năng lượng tiêu hao (TDEE)', tdee, 'calo/ngày'),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 28, bottom: 8),
          child: Row(
            children: [
              Text(
                'Chỉ số BMI',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
              SizedBox(width: 6),
              Icon(Icons.info_outline, color: Colors.white30, size: 18)
            ],
          ),
        ),
        Row(
          children: [
            const Text('🔥 ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                        text: 'Chỉ số BMI của bạn là ',
                        style: TextStyle(color: Colors.white70)),
                    TextSpan(
                        text: bmi.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold)),
                    const TextSpan(
                      text: ' bạn được xếp loại ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextSpan(
                        text: bmiCategory,
                        style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BMIRangeBar(
          bmi: bmi,
          width: MediaQuery.of(context).size.width - 72,
          barHeight: 18,
          pointerSize: 24,
        ),
        const SizedBox(height: 8),
        // ==== CÂN NẶNG LÝ TƯỞNG LOCAL ====
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cân nặng lý tưởng của bạn được ước tính $idealWeight',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
              const Tooltip(
                message:
                    'Dựa theo chỉ số BMI lý tưởng là 22 (khuyến nghị bởi WHO cho sức khỏe tốt nhất).',
                child:
                    Icon(Icons.info_outline, color: Colors.white54, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _caloBox({
    required double value,
    required String label,
    required bool isRight,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.horizontal(
              left: isRight ? Radius.zero : const Radius.circular(16),
              right: isRight ? const Radius.circular(16) : Radius.zero),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              value.toStringAsFixed(0),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, double value, String suffix) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)} $suffix',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  String _bmiCategoryText(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 23) return 'Bình thường';
    if (bmi < 25) return 'Tiền béo phì/ Thừa cân';
    if (bmi < 30) return 'Béo phì độ I';
    return 'Béo phì độ II';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    super.dispose();
  }
}
