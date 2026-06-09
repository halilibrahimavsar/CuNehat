import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

/// A BLoC/Cubit that manages the visibility state of sensitive information (like amounts).
///
/// This cubit persists the visibility preference using SharedPreferences,
/// so the user's choice is remembered across app sessions.
///
/// Example usage:
/// ```dart
/// BlocProvider(
///   create: (_) => AmountVisibilityCubit(),
///   child: AmountDisplay(amount: 1234.56),
/// )
/// ```
class AmountVisibilityCubit extends Cubit<bool> {
  static const String _visibilityKey = 'amount_visibility';

  /// Creates an [AmountVisibilityCubit] instance with default visible state.
  ///
  /// Automatically loads the saved visibility preference from SharedPreferences.
  /// Defaults to visible (true) if no preference is found.
  AmountVisibilityCubit() : super(true) {
    _loadVisibility();
  }

  /// Loads the visibility preference from SharedPreferences.
  Future<void> _loadVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final isVisible = prefs.getBool(_visibilityKey) ?? true;
    if (isClosed) return;
    emit(isVisible);
  }

  /// Toggles the visibility state between visible and hidden.
  ///
  /// Persists the new state to SharedPreferences immediately.
  Future<void> toggleVisibility() async {
    final newState = !state;
    if (isClosed) return;
    emit(newState);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_visibilityKey, newState);
  }

  /// Sets the visibility state to a specific value.
  ///
  /// [isVisible] The desired visibility state (true for visible, false for hidden).
  /// Persists the state to SharedPreferences immediately.
  Future<void> setVisibility(bool isVisible) async {
    if (isClosed) return;
    emit(isVisible);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_visibilityKey, isVisible);
  }
}
