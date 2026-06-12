part of 'language_bloc.dart';

abstract class LanguageEvent {}

class LanguageLoadEvent extends LanguageEvent {}

class LanguageChangeEvent extends LanguageEvent {
  final String languageCode;

  LanguageChangeEvent(this.languageCode);
}
