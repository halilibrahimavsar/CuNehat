import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill display name if available
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _displayNameController.text = authState.user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is DisplayNameUpdatedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profil ismi başarıyla güncellendi'),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else if (state is PasswordUpdatedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text('Şifre güncellendi. Lütfen tekrar giriş yapın.'),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                colorScheme.onPrimary.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.person_outline,
                              size: 40,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _displayNameController.text.isEmpty
                                ? 'Kullanıcı'
                                : _displayNameController.text,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  'Profil Ayarları',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSettingsCard(
                          theme,
                          title: 'Kişisel Bilgiler',
                          icon: Icons.person_rounded,
                          children: [
                            TextFormField(
                              controller: _displayNameController,
                              style: theme.textTheme.bodyLarge,
                              decoration: _buildInputDecoration(
                                theme,
                                label: 'Görünen İsim',
                                icon: Icons.badge_outlined,
                              ),
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                              UpdateDisplayNameEvent(
                                                name: _displayNameController
                                                    .text
                                                    .trim(),
                                              ),
                                            );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child:
                                    isLoading && state is! PasswordUpdatedState
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: colorScheme.onPrimary,
                                            ),
                                          )
                                        : const Text(
                                            'Bilgileri Güncelle',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsCard(
                          theme,
                          title: 'Güvenlik',
                          icon: Icons.security_rounded,
                          children: [
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: theme.textTheme.bodyLarge,
                              decoration: _buildInputDecoration(
                                theme,
                                label: 'Yeni Şifre',
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: theme.iconTheme.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              enabled: !isLoading,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length < 6) {
                                  return 'Şifre en az 6 karakter olmalı';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              style: theme.textTheme.bodyLarge,
                              decoration: _buildInputDecoration(
                                theme,
                                label: 'Şifreyi Onayla',
                                icon: Icons.lock_reset,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: theme.iconTheme.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              enabled: !isLoading,
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Şifreler eşleşmiyor';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          if (_passwordController
                                              .text.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('Şifre boş olamaz')),
                                            );
                                            return;
                                          }
                                          context.read<AuthBloc>().add(
                                                UpdatePasswordEvent(
                                                  password:
                                                      _passwordController.text,
                                                ),
                                              );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.errorContainer,
                                  foregroundColor: colorScheme.onErrorContainer,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.onErrorContainer,
                                        ),
                                      )
                                    : const Text(
                                        'Şifreyi Değiştir',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Şifre değişikliği sonrası oturumunuz otomatik olarak kapatılacaktır.',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    ThemeData theme, {
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      prefixIcon: Icon(icon, color: colorScheme.primary.withValues(alpha: 0.7)),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      filled: true,
      fillColor: theme.cardColor,
    );
  }
}
