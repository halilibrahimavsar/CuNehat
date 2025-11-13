// ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart';
import 'package:cunehat/config/theme/custome_theme.dart';
import 'package:flutter/material.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeStateLight()) {
    on<ThemeChangeEvent>((event, emit) {
      emit(ThemeSt(event.themeName));
    });
  }
}
