import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;
  final Widget? customIcon;

  const ErrorView({
    super.key,
    required this.message,
    this.buttonText,
    this.onPressed,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon ??
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (onPressed != null && buttonText != null) ...[
              const SizedBox(height: 24),
              _buildActionButton(context),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(150, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(buttonText!),
    );
  }

  // İsteğe bağlı: Farklı durumlar için fabrika metodlar
  factory ErrorView.withRetry({
    Key? key,
    required String message,
    required VoidCallback onRetry,
    String retryText = 'Tekrar Dene',
  }) {
    return ErrorView(
      key: key,
      message: message,
      buttonText: retryText,
      onPressed: onRetry,
    );
  }

  factory ErrorView.withGoBack({
    Key? key,
    required String message,
    required BuildContext context,
    String buttonText = 'Geri Dön',
  }) {
    return ErrorView(
      key: key,
      message: message,
      buttonText: buttonText,
      onPressed: () => Navigator.pop(context),
    );
  }

  factory ErrorView.withCustomAction({
    Key? key,
    required String message,
    required String buttonText,
    required VoidCallback onAction,
    Widget? icon,
  }) {
    return ErrorView(
      key: key,
      message: message,
      buttonText: buttonText,
      onPressed: onAction,
      customIcon: icon,
    );
  }
}
