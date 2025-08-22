// lib/features/auth/auth_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/api_service.dart';
import '../home/home_screen.dart'; // проверь путь под свой проект

/// Простая локализация без flutter_gen (ru/en)
class _L {
  final bool ru;
  _L(this.ru);

  static _L of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return _L(code == 'ru');
  }

  String get emailLabel => 'Email';
  String get emailHint => 'you@example.com';
  String get nextButton => ru ? 'Далее' : 'Next';

  String get headingSignInOrRegister =>
      ru ? 'Войти или зарегистрироваться' : 'Sign in or register';

  String get skip => ru ? 'Пропустить' : 'Skip';

  String get agreeTerms =>
      ru ? 'Регистрируясь, я соглашаюсь с условиями' : 'By registering, I agree to the terms';
  String get privacyPolicy => ru ? 'Политика конфиденциальности' : 'Privacy Policy';

  String get codeTitle => ru ? 'Подтверждение' : 'Confirmation';
  String codeSentTo(String email) =>
      ru ? 'Код отправлен на $email' : 'A code was sent to $email';
  String get signInButton => ru ? 'Войти' : 'Sign in';

  String get resendCode => ru ? 'Отправить код ещё раз' : 'Send code again';
  String resendCodeWithSeconds(int s) =>
      ru ? 'Отправить код ещё раз ($s)' : 'Send code again ($s)';

  String get errorEnterEmail => ru ? 'Введите email' : 'Enter your email';
  String get errorInvalidEmail => ru ? 'Некорректный email' : 'Invalid email';
  String errorEnterCodeFull(int n) =>
      ru ? 'Введите код полностью — $n цифр' : 'Enter full $n‑digit code';
  String get errorDigitsOnly =>
      ru ? 'Код должен содержать только цифры' : 'Code must contain digits only';
  String get errorTokenMissing => ru ? 'Токен не получен' : 'Token missing';
  String get errorSendCode => ru ? 'Не удалось отправить код' : 'Failed to send code';
  String get errorVerifyCode => ru ? 'Не удалось подтвердить код' : 'Failed to verify code';
  String get codeResent => ru ? 'Код повторно отправлен' : 'Code sent again';
}

class AuthEmailScreen extends StatefulWidget {
  const AuthEmailScreen({super.key});

  @override
  State<AuthEmailScreen> createState() => _AuthEmailScreenState();
}

class _AuthEmailScreenState extends State<AuthEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _agreed = false; // галочка

  static const _primary = Color(0xFF182857);

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(BuildContext context, String? v) {
    final t = _L.of(context);
    final s = (v ?? '').trim();
    if (s.isEmpty) return t.errorEnterEmail;
    final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!re.hasMatch(s)) return t.errorInvalidEmail;
    return null;
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) return; // без галочки не пускаем
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    try {
      await ApiService().requestCode(email);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _AuthCodeScreen(email: email)),
      );
    } catch (e) {
      if (!mounted) return;
      final t = _L.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.errorSendCode}: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPrivacy() async {
    final uri = Uri.parse('https://mclub.ae/en/pages/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _skip() {
    // Открываем приложение без токена (обнуляем стек)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _L.of(context);
    const border = OutlineInputBorder(borderRadius: BorderRadius.zero);

    return Scaffold(
      // верх без заголовка
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(child: SvgPicture.asset('assets/images/mclub_logo.svg', height: 100)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  t.headingSignInOrRegister,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Поле email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: t.emailLabel,
                  hintText: t.emailHint,
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                ),
                validator: (v) => _validateEmail(context, v),
                autofillHints: const [AutofillHints.email],
              ),

              // "Пропустить" справа под полем
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _skip,
                  style: TextButton.styleFrom(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  child: Text(
                    t.skip,
                    style: const TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ),

              // Кнопка "Далее"
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (!_loading && _agreed) ? _sendCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.nextButton),
                ),
              ),

              // Галочка и Privacy — ниже кнопки, по центру
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                    Flexible(
                      child: Text(
                        t.agreeTerms,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: InkWell(
                  onTap: _openPrivacy,
                  child: Text(
                    t.privacyPolicy,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      color: _primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== Экран ввода кода: прозрачный TextField над ячейками (поддержка нативной вставки)
class _AuthCodeScreen extends StatefulWidget {
  final String email;
  const _AuthCodeScreen({required this.email});

  @override
  State<_AuthCodeScreen> createState() => _AuthCodeScreenState();
}

class _AuthCodeScreenState extends State<_AuthCodeScreen> {
  static const int CODE_LENGTH = 6;
  static const int RESEND_SECONDS = 60;

  final _overlayCtrl = TextEditingController();
  final _overlayNode = FocusNode();

  String _code = ''; // текущий код (0..6 цифр)
  bool _loading = false;
  int _secondsLeft = RESEND_SECONDS;
  Timer? _timer;

  static const _primary = Color(0xFF182857);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _overlayNode.requestFocus();
    });
    _overlayCtrl.addListener(_onOverlayChanged);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _overlayCtrl.removeListener(_onOverlayChanged);
    _overlayCtrl.dispose();
    _overlayNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = RESEND_SECONDS);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onOverlayChanged() {
    // Берём только цифры и ограничиваем длину
    var digits = _overlayCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > CODE_LENGTH) digits = digits.substring(0, CODE_LENGTH);

    // Обновляем контроллер, чтобы курсор был в конце и текст был корректный
    if (_overlayCtrl.text != digits) {
      _overlayCtrl.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    setState(() => _code = digits);
  }

  Future<void> _verify() async {
    if (_code.length != CODE_LENGTH) {
      final t = _L.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.errorEnterCodeFull(CODE_LENGTH))));
      return;
    }
    setState(() => _loading = true);
    try {
      final ok = await ApiService().verifyCode(widget.email, _code);
      if (!ok) throw _L.of(context).errorTokenMissing;
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      final t = _L.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.errorVerifyCode}: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    try {
      await ApiService().requestCode(widget.email);
      if (!mounted) return;
      final t = _L.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.codeResent)),
      );
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      final t = _L.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.errorSendCode}: $e')),
      );
    }
  }

  // Ячейка отображения
  Widget _buildBox(int index) {
    const border = OutlineInputBorder(borderRadius: BorderRadius.zero);
    final ch = index < _code.length ? _code[index] : '';
    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: _primary, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        ch,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _L.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(t.codeTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            SvgPicture.asset('assets/images/mclub_logo.svg', height: 80),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(t.codeSentTo(widget.email)),
            ),
            const SizedBox(height: 16),

            // Стек: видимые ячейки + прозрачный TextField сверху
            Stack(
              children: [
                // Ряд ячеек
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(CODE_LENGTH, _buildBox),
                ),
                // Прозрачное поле поверх (полностью перекрывает ряд ячеек)
                Positioned.fill(
                  child: TextField(
                    controller: _overlayCtrl,
                    focusNode: _overlayNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    enableInteractiveSelection: true, // нужно для контекстного меню
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    cursorColor: Colors.transparent, // не виден курсор
                    style: const TextStyle(
                      color: Colors.transparent, // и текст не виден
                      fontSize: 1, // чтобы не прыгала высота
                    ),
                    decoration: const InputDecoration(
                      // полностью плоско и без отступов/рамок
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    // Не даём платформе сама закрывать клавиатуру
                    onEditingComplete: () {},
                    onSubmitted: (_) {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(t.signInButton),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: _secondsLeft == 0 ? _resend : null,
              style: TextButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(
                _secondsLeft == 0 ? t.resendCode : t.resendCodeWithSeconds(_secondsLeft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
