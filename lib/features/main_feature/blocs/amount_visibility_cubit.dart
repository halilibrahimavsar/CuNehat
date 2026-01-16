import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AmountVisibilityCubit extends Cubit<bool> {
  static const String _visibilityKey = 'amount_visibility';

  AmountVisibilityCubit() : super(true) {
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final isVisible = prefs.getBool(_visibilityKey) ?? true;
    emit(isVisible);
  }

  Future<void> toggleVisibility() async {
    final newState = !state;
    emit(newState);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_visibilityKey, newState);
  }

  Future<void> setVisibility(bool isVisible) async {
    emit(isVisible);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_visibilityKey, isVisible);
  }
}
