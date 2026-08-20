import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../l10n/locale_provider.dart';
import '../../providers/app_state.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/glide_logo.dart';
import '../home_shell.dart';
import 'first_time_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ---- controllers ----
  final _phone = TextEditingController();
  final _loginPassword = TextEditingController();
  final _nickname = TextEditingController();
  final _regPassword = TextEditingController();
  final _otp = TextEditingController();

  bool _isLoginTab = true; // true = Login, false = Register
  bool _otpSent = false;

  // ---- dial code ----
  String _dialCode = '+86';
  static const _dialCodes = [
    '+86', '+1', '+44', '+81', '+82', '+91', '+61', '+33', '+49',
  ];

  // ---- permissions (register only) ----
  bool _agreedToTerms = false;
  bool _locationPerm = false;
  bool _voicePerm = false;

  // ---- computed ----
  bool get _canLogin =>
      _phone.text.trim().length >= 6 &&
      _loginPassword.text.trim().isNotEmpty;

  bool get _canSendOtp =>
      _phone.text.trim().length >= 6 &&
      _agreedToTerms &&
      _locationPerm &&
      _voicePerm;

  bool get _canVerify => _otp.text.trim().length >= 4;

  bool get _canRegister =>
      _canVerify &&
      _nickname.text.trim().isNotEmpty &&
      _regPassword.text.trim().length >= 6;

  @override
  void initState() {
    super.initState();
    _phone.addListener(_onFieldChanged);
    _loginPassword.addListener(_onFieldChanged);
    _nickname.addListener(_onFieldChanged);
    _regPassword.addListener(_onFieldChanged);
    _otp.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _phone.removeListener(_onFieldChanged);
    _loginPassword.removeListener(_onFieldChanged);
    _nickname.removeListener(_onFieldChanged);
    _regPassword.removeListener(_onFieldChanged);
    _otp.removeListener(_onFieldChanged);
    _phone.dispose();
    _loginPassword.dispose();
    _nickname.dispose();
    _regPassword.dispose();
    _otp.dispose();
    super.dispose();
  }

  // ==========================================================================
  //  Actions
  // ==========================================================================

  void _handleLogin() async {
    final phone = _phone.text.trim();
    final password = _loginPassword.text.trim();
    if (phone.length < 6 || password.isEmpty) {
      showGlideSnack(context, context.t('invalid_phone'),
          icon: Icons.info_outline);
      return;
    }
    try {
      debugPrint('[LOGIN] phone=$_dialCode $phone password_len=${password.length}');
      final res = await ApiClient.instance.post(
        '/api/auth/password-login',
        data: {
          'phone': '$_dialCode $phone',
          'password': password,
        },
      );
      debugPrint('[LOGIN] response: ${res.data}');
      if (res.data['access_token'] != null) {
        ApiClient.instance.setToken(res.data['access_token']);
        final user = res.data['user'] as Map? ?? {};
        context.read<AppState>().login(
          nickname: user['nickname'] ?? 'Traveller',
          phone: user['phone'] ?? '$_dialCode $phone',
        );
        // Load avatar from backend
        final avatarB64 = user['avatar_base64'] as String?;
        if (avatarB64 != null && avatarB64.isNotEmpty) {
          context.read<AppState>().setAvatarBase64(avatarB64);
        }
        showGlideSnack(context, context.t('login_success'),
            icon: Icons.check_circle);
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeShell()),
          (route) => false,
        );
      } else {
        showGlideSnack(context, context.t('invalid_phone'),
            icon: Icons.error);
      }
    } catch (e) {
      debugPrint('[LOGIN] FAIL: $e');
      String msg = context.t('demo_notice');
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['detail'] ?? (e.response!.data as Map)['error'] ?? msg;
        debugPrint('[LOGIN] server error: $msg');
      }
      showGlideSnack(context, msg, icon: Icons.error);
    }
  }

  void _sendOtp() async {
    if (!_agreedToTerms || !_locationPerm || !_voicePerm) {
      showGlideSnack(context,
          context.t('permission_first'),
          icon: Icons.info_outline);
      return;
    }
    final phone = _phone.text.trim();
    if (phone.length < 6) {
      showGlideSnack(context, context.t('invalid_phone'),
          icon: Icons.info_outline);
      return;
    }
    try {
      debugPrint('[SEND_OTP] phone=$_dialCode $phone');
      final res = await ApiClient.instance.post('/api/auth/login', data: {
        'phone': '$_dialCode $phone',
      });
      debugPrint('[SEND_OTP] response: ${res.data}');
      setState(() => _otpSent = true);
      final otp = res.data['otp'];
      showGlideSnack(
        context,
        otp != null
            ? '${context.t('demo_code_sent')} → $otp'
            : context.t('demo_code_sent'),
        icon: Icons.sms,
      );
    } catch (e) {
      debugPrint('[SEND_OTP] FAIL: $e');
      String msg = context.t('demo_notice');
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['detail'] ?? (e.response!.data as Map)['error'] ?? msg;
        debugPrint('[SEND_OTP] server error: $msg');
      }
      showGlideSnack(context, msg, icon: Icons.error);
    }
  }

  void _handleRegister() async {
    if (!_canRegister) {
      showGlideSnack(context, context.t('enter_code_prompt'),
          icon: Icons.info_outline);
      return;
    }
    final phone = _phone.text.trim();
    final nickname = _nickname.text.trim();
    final password = _regPassword.text.trim();
    final otp = _otp.text.trim();
    try {
      debugPrint('[REGISTER] phone=$_dialCode $phone nickname=$nickname password_len=${password.length} otp=$otp');
      final res = await ApiClient.instance.post('/api/auth/register', data: {
        'phone': '$_dialCode $phone',
        'nickname': nickname.isNotEmpty ? nickname : 'Traveller',
        'password': password,
        'otp': otp,
      });
      debugPrint('[REGISTER] response: ${res.data}');
      if (res.data['access_token'] != null) {
        ApiClient.instance.setToken(res.data['access_token']);
        final user = res.data['user'] as Map? ?? {};
        context.read<AppState>().login(
          nickname: user['nickname'] ?? 'Traveller',
          phone: user['phone'] ?? '$_dialCode $phone',
        );
        context.read<AppState>().setIsNewRegistration(true);
        // Load avatar from backend
        final avatarB64 = user['avatar_base64'] as String?;
        if (avatarB64 != null && avatarB64.isNotEmpty) {
          context.read<AppState>().setAvatarBase64(avatarB64);
        }
        showGlideSnack(context, context.t('register_success'),
            icon: Icons.check_circle);
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FirstTimeScreen()),
        );
      } else {
        showGlideSnack(context, context.t('demo_notice'),
            icon: Icons.error);
      }
    } catch (e) {
      debugPrint('[REGISTER] FAIL: $e');
      String msg = context.t('demo_notice');
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['detail'] ?? (e.response!.data as Map)['error'] ?? msg;
        debugPrint('[REGISTER] server error: $msg');
      }
      showGlideSnack(context, msg, icon: Icons.error);
    }
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card)),
        title: Text(context.t('terms_title'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Text(context.t('terms_content'),
              style: const TextStyle(height: 1.6, color: AppColors.inkSoft)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('continue'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  //  Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlideBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                // ============================================================
                // Header: logo only (no back button, no text)
                // ============================================================
                const SizedBox(height: 8),
                const GlideLogo(size: 56),
                const SizedBox(height: 28), // push content down
                // ============================================================
                // Title & hint
                // ============================================================
                Text(
                  _isLoginTab ? context.t('welcome_back') : context.t('register_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLoginTab ? context.t('login_hint') : context.t('register_hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.inkSoft, fontSize: 15),
                ),
                const SizedBox(height: 24),
                // ============================================================
                // Tab switcher
                // ============================================================
                _buildTabSwitcher(),
                const SizedBox(height: 20),
                // ============================================================
                // Scrollable form area
                // ============================================================
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isLoginTab) ..._loginFields(),
                        if (!_isLoginTab) ..._registerFields(),
                      ],
                    ),
                  ),
                ),
                // ============================================================
                // Bottom button
                // ============================================================
                GradientButton(
                  label: _isLoginTab
                      ? context.t('login_action')
                      : (_otpSent
                          ? context.t('register_action')
                          : context.t('send_code')),
                  icon: Icons.arrow_forward,
                  onPressed: _isLoginTab
                      ? (_canLogin ? _handleLogin : null)
                      : (_otpSent
                          ? (_canRegister ? _handleRegister : null)
                          : (_phone.text.trim().length >= 6 ? _sendOtp : null)),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    context.t('demo_notice'),
                    style: const TextStyle(
                        color: AppColors.inkFaint, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  //  Sub-widgets
  // ==========================================================================

  Widget _buildTabSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginTab = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isLoginTab ? AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.chip - 2),
                ),
                child: Center(
                  child: Text(
                    context.t('login_tab'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _isLoginTab ? Colors.white : AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isLoginTab = false;
                _otpSent = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isLoginTab ? AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.chip - 2),
                ),
                child: Center(
                  child: Text(
                    context.t('register_tab'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: !_isLoginTab ? Colors.white : AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Login fields ----
  List<Widget> _loginFields() {
    return [
      _label(context.t('phone_number')),
      const SizedBox(height: 8),
      _buildPhoneRow(),
      const SizedBox(height: 16),
      _label(context.t('password')),
      const SizedBox(height: 8),
      _buildPasswordField(
        controller: _loginPassword,
        hint: context.t('password_hint'),
      ),
    ];
  }

  // ---- Register fields ----
  List<Widget> _registerFields() {
    return [
      _label(context.t('phone_number')),
      const SizedBox(height: 8),
      _buildPhoneRow(),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(context.t('send_code_hint'),
            style: const TextStyle(
                color: AppColors.inkFaint, fontSize: 12.5)),
      ),
      const SizedBox(height: 16),
      _label(context.t('nickname')),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _nickname,
        hint: context.t('nickname_hint'),
        icon: Icons.person_outline,
      ),
      const SizedBox(height: 16),
      _label(context.t('password')),
      const SizedBox(height: 8),
      _buildPasswordField(
        controller: _regPassword,
        hint: context.t('password_6_digits'),
        maxLength: 6,
      ),
      const SizedBox(height: 16),
      _label(context.t('verification_code')),
      const SizedBox(height: 8),
      _buildCodeRow(),
      if (_otpSent) ...[
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '${context.t('code_sent_to')} $_dialCode ... ${_phone.text.length >= 4 ? _phone.text.substring(_phone.text.length - 4) : ""}',
            style: const TextStyle(
                color: AppColors.inkFaint, fontSize: 12.5),
          ),
        ),
      ],
      if (!_otpSent) ...[
        const SizedBox(height: 12),
        _permissionRow(
          checked: _agreedToTerms,
          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
          child: _termsText(),
        ),
        const SizedBox(height: 4),
        _permissionRow(
          checked: _locationPerm,
          onChanged: (v) => _handleLocationPermission(v ?? false),
          label: context.t('allow_location'),
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 4),
        _permissionRow(
          checked: _voicePerm,
          onChanged: (v) => _handleMicPermission(v ?? false),
          label: context.t('allow_voice'),
          icon: Icons.mic_outlined,
        ),
      ],
    ];
  }

  // ---- Permission handlers ----

  /// When the user ticks "Allow location", request the real OS permission.
  /// The box stays checked only if permission is actually granted.
  Future<void> _handleLocationPermission(bool wants) async {
    setState(() => _locationPerm = wants);
    if (wants) {
      await Permission.location.request();
    }
  }

  /// When the user ticks "Allow microphone", request the real OS permission.
  Future<void> _handleMicPermission(bool wants) async {
    setState(() => _voicePerm = wants);
    if (wants) {
      await Permission.microphone.request();
    }
  }

  // ---- Reusable field builders ----
  Widget _buildPhoneRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            boxShadow: AppShadows.soft,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _dialCode,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
              dropdownColor: AppColors.surface,
              iconEnabledColor: AppColors.ink,
              iconDisabledColor: AppColors.inkFaint,
              borderRadius: BorderRadius.circular(AppRadii.chip),
              items: _dialCodes
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
              onChanged: _otpSent
                  ? null
                  : (v) => setState(() => _dialCode = v!),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.chip),
              boxShadow: AppShadows.soft,
            ),
            child: TextField(
              controller: _phone,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.teal,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              ],
              decoration: InputDecoration(
                hintText: context.t('phone_hint'),
                hintStyle: const TextStyle(color: AppColors.inkFaint),
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.inkFaint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        boxShadow: AppShadows.soft,
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: AppColors.teal,
        obscureText: true,
        maxLength: maxLength,
        keyboardType: TextInputType.visiblePassword,
        inputFormatters: [
          if (maxLength != null) FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.inkFaint),
          counterText: '',
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.inkFaint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        boxShadow: AppShadows.soft,
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: AppColors.teal,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.inkFaint),
          prefixIcon: Icon(icon, color: AppColors.inkFaint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildCodeRow() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _otp,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.teal,
              enabled: _otpSent,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: context.t('code_hint'),
                hintStyle: const TextStyle(color: AppColors.inkFaint),
                counterText: '',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.inkFaint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionRow({
    required bool checked,
    required ValueChanged<bool?> onChanged,
    String? label,
    IconData? icon,
    Widget? child,
  }) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: AppColors.teal,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 10),
        if (child != null)
          Expanded(child: child)
        else ...[
          if (icon != null)
            Icon(icon, size: 18, color: AppColors.teal),
          if (icon != null) const SizedBox(width: 6),
          Expanded(
            child: Text(label ?? '',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.inkSoft, height: 1.3)),
          ),
        ],
      ],
    );
  }

  Widget _termsText() {
    return Expanded(
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
              fontSize: 13, color: AppColors.inkSoft, height: 1.3),
          children: [
            TextSpan(text: context.t('agree_terms')),
            TextSpan(
              text: context.t('terms_link'),
              style: const TextStyle(
                  color: AppColors.teal, fontWeight: FontWeight.w700),
              recognizer: TapGestureRecognizer()..onTap = _showTerms,
            ),
            TextSpan(text: context.t('and')),
            TextSpan(
              text: context.t('privacy_link'),
              style: const TextStyle(
                  color: AppColors.teal, fontWeight: FontWeight.w700),
              recognizer: TapGestureRecognizer()..onTap = _showTerms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 15)),
      );
}
