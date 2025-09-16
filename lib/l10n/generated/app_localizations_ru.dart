// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'М-Клуб';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get clubCard => 'Клубная карта';

  @override
  String get profile => 'Профиль';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get retry => 'Повторить';

  @override
  String get logout => 'Выйти';
}
