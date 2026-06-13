import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';

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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      home: Builder(builder: (context) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.error_outline, size: 56, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.uygulamaBaslatilamadi,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!
                        .verilerinizSilinmediTekrarDeneyin,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text(AppLocalizations.of(context)!.hataDetayi),
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
                    label: Text(AppLocalizations.of(context)!.tekrarDene),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
