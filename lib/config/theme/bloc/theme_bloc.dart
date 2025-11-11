// ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart';
import 'package:cunehat/config/theme/custome_theme.dart';

part 'theme_event.dart';
part 'theme_state.dart';

final CustomeAppThemes customeAppTheme = CustomeAppThemes();

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeSt("Dark")) {
    on<ThemeChangeEvent>((event, emit) {
      emit(ThemeSt(event.themeName));
    });
  }
}
