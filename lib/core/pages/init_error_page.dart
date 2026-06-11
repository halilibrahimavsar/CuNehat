import 'package:flutter/material.dart';

/// Açılış (Hive/DI) başarısız olduğunda gösterilen bağımsız mini uygulama.
///
/// Normal ağaç hiç kurulamadığı için tema/DI/router'a dayanmaz; tek işi
/// hatayı söyleyip "Tekrar Dene" ile [buildApp]'i yeniden çalıştırmak,
/// başarıda gerçek uygulama ağacına geçmektir. Veri silme YOK.
class InitErrorApp extends StatefulWidget {
  final String error;

  /// Gerçek uygulama ağacını kuran closure (main.dart'taki init akışı).
  final Future<Widget> Function() buildApp;

  const InitErrorApp({
    super.key,
    required this.error,
    required this.buildApp,
  });

  @override
  State<InitErrorApp> createState() => _InitErrorAppState();
}

class _InitErrorAppState extends State<InitErrorApp> {
  Widget? _app;
  bool _retrying = false;
  late String _error = widget.error;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      final app = await widget.buildApp();
      if (!mounted) return;
      setState(() => _app = app);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _retrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_app != null) return _app!;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Uygulama başlatılamadı',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verileriniz silinmedi. Tekrar deneyin; sorun sürerse '
                  'cihazı yeniden başlatıp uygulamayı yeniden açın.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Hata detayı'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error,
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _retrying ? null : _retry,
                  icon: _retrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
