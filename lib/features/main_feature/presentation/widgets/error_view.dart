import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 58, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text("Veriler yüklenemedi",
              style: TextStyle(color: Colors.red.shade700)),
          const SizedBox(height: 4),
          Text(errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text("Tekrar Dene"),
          ),
        ],
      ),
    );
  }
}
