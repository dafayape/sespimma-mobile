import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

const Color _primaryNavy = Color(0xFF000B1D);
const Color _lightGrey = Color(0xFFF8F9FA);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
    _initAnimations();
  }

  void _setupSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      body: BlocListener<AuthBloc, AuthState>(
        listener: _handleAuthState,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxHeight < 700;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: isSmallScreen ? 16.0 : 32.0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LoginHeader(isSmallScreen: isSmallScreen),
                            SizedBox(
                              height: isSmallScreen
                                  ? AppDimensions.lg
                                  : AppDimensions.avatarMd,
                            ),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: LoginForm(isSmallScreen: isSmallScreen),
                              ),
                            ),
                            SizedBox(
                              height: isSmallScreen
                                  ? AppDimensions.xl
                                  : AppDimensions.xxl + 16,
                            ),
                            LoginFooter(isSmallScreen: isSmallScreen),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      Navigator.pushReplacementNamed(context, '/main');
    } else if (state is AuthFailure) {
      AppNotifier.showError(context, state.message);
    } else if (state is AuthNrpValidationSuccess) {
      Navigator.pushNamed(context, '/forgot-password', arguments: state.nrp);
    }
  }
}

class LoginHeader extends StatelessWidget {
  final bool isSmallScreen;

  const LoginHeader({super.key, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppIcon(),
        SizedBox(height: isSmallScreen ? AppDimensions.md : AppDimensions.lg),
        _buildAppTitle(),
        const SizedBox(height: AppDimensions.sm),
        _buildAppSubtitle(),
      ],
    );
  }

  Widget _buildAppIcon() {
    return Image.asset(
      'assets/images/icon.png',
      height: isSmallScreen ? 100 : 140,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.local_police,
        size: isSmallScreen ? 80 : 120,
        color: _primaryNavy,
      ),
    );
  }

  Widget _buildAppTitle() {
    return Text(
      'SESPIMMA',
      style: TextStyle(
        fontSize: isSmallScreen
            ? AppDimensions.fontDisplay
            : AppDimensions.fontDisplayXl,
        fontWeight: FontWeight.w800,
        color: _primaryNavy,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAppSubtitle() {
    return Text(
      'SISTEM EVALUASI DAN PENGAWASAN INDIVIDU MEMBENTUK SUMBER DAYA MANUSIA MAJU',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isSmallScreen
            ? AppDimensions.fontSm + 1
            : AppDimensions.fontMd,
        fontWeight: FontWeight.w600,
        color: Colors.blueGrey.shade400,
        letterSpacing: isSmallScreen ? 0.5 : 1.2,
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final bool isSmallScreen;

  const LoginForm({super.key, required this.isSmallScreen});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _nrpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  static const String _nrpStorageKey = 'saved_nrp';
  static const String _passwordStorageKey = 'saved_password';

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isNip = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _nrpController.addListener(_checkIfNip);
  }

  @override
  void dispose() {
    _nrpController.removeListener(_checkIfNip);
    _nrpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkIfNip() {
    final isNipNow = _nrpController.text.length > 10;
    if (isNipNow != _isNip) {
      setState(() => _isNip = isNipNow);
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedNrp = await _secureStorage.read(key: _nrpStorageKey);
      final savedPassword = await _secureStorage.read(key: _passwordStorageKey);
      if (savedNrp != null && savedNrp.isNotEmpty) {
        setState(() {
          _nrpController.text = savedNrp;
          if (savedPassword != null && savedPassword.isNotEmpty) {
            _passwordController.text = savedPassword;
          }
          _rememberMe = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to read from secure storage: $e');
    }
  }

  Future<void> _handleRememberMeStorage() async {
    try {
      if (_rememberMe) {
        await _secureStorage.write(
          key: _nrpStorageKey,
          value: _nrpController.text.trim(),
        );
        await _secureStorage.write(
          key: _passwordStorageKey,
          value: _passwordController.text,
        );
      } else {
        await _secureStorage.delete(key: _nrpStorageKey);
        await _secureStorage.delete(key: _passwordStorageKey);
      }
    } catch (e) {
      debugPrint('Failed to write to secure storage: $e');
    }
  }

  void _submitLogin() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      _handleRememberMeStorage();
      context.read<AuthBloc>().add(
        LoginSubmitted(
          nrp: _nrpController.text.trim(),
          password: _passwordController.text,
          fcmToken: 'DUMMY_TOKEN',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        widget.isSmallScreen ? AppDimensions.lg : AppDimensions.xxl + 4,
      ),
      decoration: _buildCardDecoration(),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextFieldLabel(_isNip ? 'NIP' : 'NRP'),
            const SizedBox(height: AppDimensions.sm),
            _buildNrpField(),
            SizedBox(
              height: widget.isSmallScreen
                  ? AppDimensions.lg
                  : AppDimensions.xl,
            ),
            _buildTextFieldLabel('Password'),
            const SizedBox(height: AppDimensions.sm),
            _buildPasswordField(),
            SizedBox(
              height: widget.isSmallScreen
                  ? AppDimensions.sm
                  : AppDimensions.md,
            ),
            _buildFormActions(context),
            SizedBox(
              height: widget.isSmallScreen
                  ? AppDimensions.lg
                  : AppDimensions.xxl + 4,
            ),
            _buildSubmitButton(),
            SizedBox(
              height: widget.isSmallScreen
                  ? AppDimensions.lg
                  : AppDimensions.xl,
            ),
            _buildSecureBadge(),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildTextFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AppDimensions.fontDefault,
        fontWeight: FontWeight.w600,
        color: Colors.blueGrey.shade700,
      ),
    );
  }

  Widget _buildNrpField() {
    return TextFormField(
      controller: _nrpController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: _validateNrp,
      decoration: _inputDecoration(
        hint: 'Masukkan ${_isNip ? 'NIP' : 'NRP'}',
        icon: AppIcons.user,
      ).copyWith(suffixIcon: _buildNrpClearIcon()),
    );
  }

  String? _validateNrp(String? value) {
    if (value == null || value.isEmpty) {
      return '${_isNip ? 'NIP' : 'NRP'} tidak boleh kosong';
    }
    if (value.length < 5) {
      return '${_isNip ? 'NIP' : 'NRP'} tidak valid';
    }
    return null;
  }

  Widget _buildNrpClearIcon() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _nrpController,
      builder: (context, value, child) {
        if (value.text.isEmpty) return const SizedBox.shrink();
        return IconButton(
          icon: Icon(
            AppIcons.xCircle,
            color: Colors.grey.shade400,
            size: AppDimensions.iconDefault,
          ),
          onPressed: _nrpController.clear,
        );
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submitLogin(),
      validator: _validatePassword,
      decoration: _inputDecoration(
        hint: 'Masukkan Password',
        icon: AppIcons.lockKey,
      ).copyWith(suffixIcon: _buildPasswordToggleIcon()),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  Widget _buildPasswordToggleIcon() {
    return IconButton(
      icon: Icon(
        _isPasswordVisible ? AppIcons.eyeSlash : AppIcons.eye,
        color: Colors.grey.shade500,
        size: AppDimensions.iconDefault + 2,
      ),
      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
    );
  }

  Widget _buildFormActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildRememberMeCheckbox(),
        _buildForgotPasswordButton(context),
      ],
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Expanded(
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: _rememberMe,
              onChanged: (value) =>
                  setState(() => _rememberMe = value ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
              side: BorderSide(color: Colors.grey.shade400),
              activeColor: _primaryNavy,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Flexible(
            child: Text(
              'Ingat Saya',
              style: TextStyle(
                fontSize: AppDimensions.fontDefault,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        final nrp = _nrpController.text.trim();
        if (nrp.isEmpty) {
          AppNotifier.showError(
            context,
            '${_isNip ? 'NIP' : 'NRP'} tidak boleh kosong',
          );
        } else {
          context.read<AuthBloc>().add(VerifyNrpRequested(nrp));
        }
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: const Text(
        'Lupa Password?',
        style: TextStyle(
          fontSize: AppDimensions.fontDefault,
          fontWeight: FontWeight.w700,
          color: _primaryNavy,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return ElevatedButton(
          onPressed: isLoading ? null : _submitLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'MASUK',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg + 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSecureBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          AppIcons.shieldCheckFill,
          size: AppDimensions.iconDefault,
          color: Colors.green.shade600,
        ),
        const SizedBox(width: AppDimensions.sm),
        Text(
          'SECURE ACCESS',
          style: TextStyle(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.blueGrey.shade300,
        fontSize: AppDimensions.fontLg,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.blueGrey.shade400,
        size: AppDimensions.iconDefault + 2,
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: _primaryNavy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}

class LoginFooter extends StatelessWidget {
  final bool isSmallScreen;

  const LoginFooter({super.key, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Text(
      '© ${DateTime.now().year} SESPIMMA LEMDIKLAT POLRI. ALL RIGHTS RESERVED.',
      style: TextStyle(
        fontSize: isSmallScreen
            ? AppDimensions.fontSm
            : AppDimensions.fontSm + 1,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }
}
