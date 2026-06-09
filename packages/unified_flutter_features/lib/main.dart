import 'package:flutter/material.dart';
import 'package:unified_flutter_features/core/constants/app_colors.dart';
import 'package:unified_flutter_features/shared_features.dart';
import 'package:unified_flutter_features/core/constants/app_spacing.dart';

void main() {
  runApp(const UnifiedFeaturesDemoApp());
}

class UnifiedFeaturesDemoApp extends StatelessWidget {
  const UnifiedFeaturesDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unified Features Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Unified Features Demo'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Shared Features Section
            _buildSharedFeaturesSection(),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            // Buttons Gallery Section
            _buildButtonsGallery(),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedFeaturesSection() {
    return Card(
      child: Padding(
        padding: AppSpacing.mediumAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shared Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                IboGlassButton(
                  text: 'Tarih Seç',
                  backgroundColor: AppColors.success,
                  onPressed: () => _showDatePickerDemo(),
                ),
                IboGlassButton(
                  text: 'Tarih Aralığı',
                  backgroundColor: AppColors.secondary,
                  onPressed: () => _showDateRangePickerDemo(),
                ),
                IboGlassButton(
                  text: 'Dialog',
                  backgroundColor: AppColors.primary,
                  onPressed: () => _showDialogDemo(),
                ),
                IboGlassButton(
                  text: 'Metin Giriş',
                  backgroundColor: AppColors.warning,
                  onPressed: () => _showTextInputDemo(),
                ),
                IboGlassButton(
                  text: 'Yükle',
                  backgroundColor: AppColors.error,
                  onPressed: () => _showSnackbarDemo(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsGallery() {
    return Card(
      child: Padding(
        padding: AppSpacing.mediumAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buton Galerisi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: IboGlassButton(
                        text: 'Başarılı',
                        backgroundColor: AppColors.success,
                        onPressed: () => IboSnackbar.showSuccess(
                          context,
                          'Bu bir başarı mesajıdır!',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: IboGlassButton(
                        text: 'Hata',
                        backgroundColor: AppColors.error,
                        onPressed: () => IboSnackbar.showError(
                          context,
                          'Bu bir hata mesajıdır!',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: IboLoadingButton(
                        text: 'Yükleme Butonu',
                        backgroundColor: AppColors.primary,
                        onPressed: () async {
                          await Future<void>.delayed(
                            const Duration(seconds: 2),
                          );
                          if (!mounted) return;
                          IboSnackbar.showSuccess(
                            context,
                            'Yükleme tamamlandı!',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: IboGlassButton(
                        text: 'Onay Dialog',
                        backgroundColor: AppColors.warning,
                        onPressed: () async {
                          final confirmed = await IboDialog.showConfirmation(
                            context,
                            'Onay Gerekli',
                            'Bu işlemi gerçekleştirmek istediğinizden emin misiniz?',
                          );
                          if (!mounted) return;
                          if (confirmed == true) {
                            IboSnackbar.showSuccess(
                              context,
                              'İşlem onaylandı!',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePickerDemo() async {
    final date = await IboDatePicker.pickDate(
      context,
      quickOptions: _buildDateQuickOptions(),
    );
    if (!mounted) return;
    if (date != null) {
      IboSnackbar.showSuccess(
        context,
        'Seçilen tarih: ${date.toString().substring(0, 10)}',
      );
    }
  }

  Future<void> _showDateRangePickerDemo() async {
    final range = await IboDateRangePicker.pickDateRange(
      context,
      quickOptions: _buildDateRangeQuickOptions(),
    );
    if (!mounted) return;
    if (range != null) {
      IboSnackbar.showSuccess(
        context,
        'Seçilen aralık: ${range.start.toString().substring(0, 10)} - '
        '${range.end.toString().substring(0, 10)}',
      );
    }
  }

  Future<void> _showDialogDemo() async {
    await IboDialog.showInfo(
      context,
      'Bilgi',
      'Bu bir bilgilendirme diyalogudur. İstenildiği gibi özelleştirilebilir.',
    );
  }

  Future<void> _showTextInputDemo() async {
    final text = await IboDialog.showTextInput(
      context,
      'Metin Girişi',
      'Lütfen adınızı girin',
    );
    if (!mounted) return;
    if (text != null && text.isNotEmpty) {
      IboSnackbar.showSuccess(context, 'Merhaba $text!');
    }
  }

  void _showSnackbarDemo() {
    IboSnackbar.showWarning(context, 'Bu bir uyarı mesajıdır!');
  }

  List<IboDateQuickOption> _buildDateQuickOptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      IboDateQuickOption(label: 'Bugün', date: today),
      IboDateQuickOption(
        label: 'Dün',
        date: today.subtract(const Duration(days: 1)),
      ),
      IboDateQuickOption(
        label: 'Yarın',
        date: today.add(const Duration(days: 1)),
      ),
    ];
  }

  List<IboDateRangeQuickOption> _buildDateRangeQuickOptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = (now.month == 12)
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    final endOfMonth = startOfNextMonth.subtract(const Duration(days: 1));
    final startOfLastMonth = (now.month == 1)
        ? DateTime(now.year - 1, 12, 1)
        : DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = startOfMonth.subtract(const Duration(days: 1));

    return [
      IboDateRangeQuickOption(
        label: 'Son 7 Gün',
        range: DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        ),
      ),
      IboDateRangeQuickOption(
        label: 'Bu Ay',
        range: DateTimeRange(start: startOfMonth, end: endOfMonth),
      ),
      IboDateRangeQuickOption(
        label: 'Geçen Ay',
        range: DateTimeRange(start: startOfLastMonth, end: endOfLastMonth),
      ),
    ];
  }
}
