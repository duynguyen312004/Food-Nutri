import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/user_service.dart';
import 'user_data_state.dart';

class UserDataCubit extends Cubit<UserDataState> {
  final UserService _userService;
  UserDataCubit(this._userService) : super(UserDataInitial());

  // Load profile, goal, settings từ backend
  Future<void> loadUserData() async {
    emit(UserDataLoading());
    try {
      final profile = await _userService.fetchProfile();
      final goal = await _userService.fetchGoal(); // tạo ở service
      final settings = await _userService.fetchSettings(); // đã có
      emit(UserDataLoaded(
        profile: profile,
        goal: goal,
        settings: settings,
      ));
    } catch (e) {
      emit(UserDataError(e.toString()));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    emit(UserDataLoading());
    try {
      await _userService.updateProfile(data);
      final updated = await _userService.fetchProfile();
      final goal = await _userService.fetchGoal();
      final settings = await _userService.fetchSettings();

      emit(UserDataLoaded(
        profile: updated,
        goal: goal,
        settings: settings,
      ));
    } catch (e) {
      emit(UserDataError(e.toString()));
    }
  }

  void clearUserData() {
    emit(UserDataInitial());
  }
}
