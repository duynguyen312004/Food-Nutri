import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nutrition_app/blocs/food/recipe_cubit.dart';
import '../blocs/user/user_data_cubit.dart';
import '../blocs/log/journal_cubit.dart';
import '../blocs/metrics/metrics_cubit.dart';
import '../blocs/recent_log/recent_meals_cubit.dart';

class AppStateCleaner {
  static void clearAll(BuildContext context) {
    context.read<UserDataCubit>().clearUserData();
    context.read<JournalCubit>().clearJournalData();
    context.read<MetricsCubit>().clearMetricsData();
    context.read<RecentMealsCubit>().clearRecentMeals();
    context.read<RecipeCubit>().reset();
  }
}
