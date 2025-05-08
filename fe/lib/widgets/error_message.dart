import 'package:flutter/material.dart';

/// Widget hiển thị text lỗi
class ErrorMessage extends StatelessWidget {
  final String text;
  const ErrorMessage({required this.text, super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
}
