import 'package:flutter/material.dart';

/// Widget đơn giản hiển thị loading spinner
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      );
}
