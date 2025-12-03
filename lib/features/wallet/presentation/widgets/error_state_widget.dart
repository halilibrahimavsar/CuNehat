import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  final String errorMessage;

  const ErrorStateWidget({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text('Hata: $errorMessage'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
