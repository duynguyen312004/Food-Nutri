import 'package:flutter/material.dart';
import 'package:nutrition_app/ui/setup_profiles.dart/loading_setup_screen.dart';
import 'step_name.dart';
import 'step_goal.dart';
import 'step_gender.dart';
import 'step_dob.dart';
import 'step_height.dart';
import 'step_weight_current.dart';
import 'step_weight_target.dart';
import 'step_progress.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ProfileSetupScreenState createState() => ProfileSetupScreenState();
}

class ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();

  final _formKeyName = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  String? _selectedGoal;
  String? _selectedGender;
  DateTime? _selectedDob;
  double? _heightCm;
  double? _currentWeight;
  double? _targetWeight;
  String? _progressPlan;

  bool _isLoading = false;

  static const Map<String, double> _paceMap = {
    'Thư giãn': 0.5,
    'Ổn định': 0.75,
    'Tăng cường': 1,
  };

  @override
  void dispose() {
    _pageController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (_isLoading) return;
    if ((_pageController.page ?? 0) > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _onNext() {
    final idx = (_pageController.page ?? 0).toInt();

    if (idx == 0 && !(_formKeyName.currentState?.validate() ?? false)) return;
    if (idx == 1 && _selectedGoal == null) return;
    if (idx == 2 && _selectedGender == null) return;
    if (idx == 3 && _selectedDob == null) return;
    if (idx == 4 &&
        (_heightCm ?? double.tryParse(_heightController.text)) == null) return;
    if (idx == 5 &&
        (_currentWeight ?? double.tryParse(_currentWeightController.text)) ==
            null) return;
    if (idx == 6 &&
        (_targetWeight ?? double.tryParse(_targetWeightController.text)) ==
            null) return;
    if (idx == 7 && _progressPlan == null) return;

    if (idx < 7) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
    }
  }

  Future<void> _submitProfile() async {
    setState(() => _isLoading = true);

    final parsedHeight = _heightCm ?? double.tryParse(_heightController.text);
    final parsedCurrentWeight =
        _currentWeight ?? double.tryParse(_currentWeightController.text);
    final parsedTargetWeight =
        _targetWeight ?? double.tryParse(_targetWeightController.text);

    int durationWeeks = 4;
    if (parsedCurrentWeight != null &&
        parsedTargetWeight != null &&
        _progressPlan != null) {
      final diff = (parsedCurrentWeight - parsedTargetWeight).abs();
      final pace = _paceMap[_progressPlan!] ?? 1;
      if (pace > 0) durationWeeks = (diff / pace).ceil();
    }

    final data = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'date_of_birth': _selectedDob?.toIso8601String(),
      'gender': _selectedGender,
      'height_cm': parsedHeight,
      'current_weight_kg': parsedCurrentWeight,
      'target_weight_kg': parsedTargetWeight,
      'goal_direction': _selectedGoal?.toLowerCase(),
      'duration_weeks': durationWeeks,
      'weekly_rate': _paceMap[_progressPlan],
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoadingSetupScreen(data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = (_pageController.hasClients ? _pageController.page : 0) ?? 0;
    final isLast = idx.toInt() == 7;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(idx.toInt()),
            Expanded(
              child: PageView(
                key: const PageStorageKey('profile_setup_pageview'),
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  NameStep(
                    formKey: _formKeyName,
                    lastNameController: _lastNameController,
                    firstNameController: _firstNameController,
                  ),
                  GoalStep(
                    selectedGoal: _selectedGoal,
                    onGoalSelected: (val) =>
                        setState(() => _selectedGoal = val),
                  ),
                  GenderStep(
                    selectedGender: _selectedGender,
                    onGenderSelected: (val) =>
                        setState(() => _selectedGender = val),
                  ),
                  DobStep(
                    selectedDob: _selectedDob,
                    onDobSelected: (date) =>
                        setState(() => _selectedDob = date),
                  ),
                  HeightStep(
                    controller: _heightController,
                    onChanged: (v) =>
                        setState(() => _heightCm = double.tryParse(v)),
                  ),
                  CurrentWeightStep(
                    controller: _currentWeightController,
                    onChanged: (v) =>
                        setState(() => _currentWeight = double.tryParse(v)),
                  ),
                  TargetWeightStep(
                    controller: _targetWeightController,
                    currentWeight: _currentWeight,
                    onChanged: (v) =>
                        setState(() => _targetWeight = double.tryParse(v)),
                  ),
                  ProgressStep(
                    selectedPlan: _progressPlan,
                    onPlanSelected: (val) =>
                        setState(() => _progressPlan = val),
                    currentWeight: _currentWeight,
                    targetWeight: _targetWeight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            TextButton(onPressed: _onBack, child: const Text('Quay lại')),
            const Spacer(),
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBFF23B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(120, 50),
                ),
                child: Text(
                  isLast ? 'Hoàn thành' : 'Tiếp tục',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: _onBack),
          const SizedBox(width: 12),
          Text(
            '${step + 1}/8',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Image.asset('assets/images/logo.png', width: 32, height: 32),
        ],
      ),
    );
  }
}
