import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isOldPassVisible = false;
  bool _isPassVisible = false;
  bool _isConfirmPassVisible = false;

  bool _hasMinLength = false;
  bool _hasCapital = false;
  bool _hasNumber = false;
  String? _nrp;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nrp = ModalRoute.of(context)?.settings.arguments as String?;
  }

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
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
    _passController.addListener(_validatePasswordStrength);
  }

  void _validatePasswordStrength() {
    final value = _passController.text;
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasCapital = value.contains(RegExp(r'[A-Z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
    });
  }

  @override
  void dispose() {
    _passController.removeListener(_validatePasswordStrength);
    _animationController.dispose();
    _oldPassController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _submitNewPassword(bool isAuthenticated) {
    FocusScope.of(context).unfocus();

    if (!_hasMinLength || !_hasCapital || !_hasNumber) {
      HapticFeedback.mediumImpact();
      AppNotifier.showError(
        context,
        'Mohon lengkapi kriteria keamanan password baru Anda.',
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();

      if (isAuthenticated) {
        context.read<AuthBloc>().add(
          ChangePasswordRequested(
            oldPassword: _oldPassController.text,
            newPassword: _passController.text,
          ),
        );
      } else {
        context.read<AuthBloc>().add(
          ResetPasswordRequested(
            nrp: _nrp ?? '',
            newPassword: _passController.text,
          ),
        );
      }

      AppNotifier.showSuccess(context, 'Password berhasil diperbarui!');

      if (isAuthenticated) {
        Navigator.pop(context);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          HapticFeedback.vibrate();
          AppNotifier.showError(context, state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final bool isAuthenticated = state is AuthSuccess;
          final bool isLoading = state is AuthLoading;

          return Stack(
            children: [
              Scaffold(
                backgroundColor: _lightGrey,
                appBar: AppBar(
                  backgroundColor: _lightGrey,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      AppIcons.caretLeft,
                      size: AppDimensions.iconXl,
                    ),
                    color: _primaryNavy,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text(
                    'Atur Ulang Password',
                    style: TextStyle(
                      color: _primaryNavy,
                      fontWeight: FontWeight.w700,
                      fontSize: AppDimensions.fontXxl,
                    ),
                  ),
                  centerTitle: true,
                ),
                body: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 24.0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(
                                AppDimensions.xl - 4,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryNavy.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.shieldCheck,
                                size: AppDimensions.iconDisplay,
                                color: _primaryNavy,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.xl),
                            const Text(
                              'Buat Password Baru',
                              style: TextStyle(
                                fontSize: AppDimensions.fontDisplay,
                                fontWeight: FontWeight.w800,
                                color: _primaryNavy,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.sm),
                            if (_nrp != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryNavy.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd,
                                  ),
                                ),
                                child: Text(
                                  '${(_nrp?.length ?? 0) > 8 ? 'NIP' : 'NRP'}: $_nrp',
                                  style: const TextStyle(
                                    fontSize: AppDimensions.fontMd,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryNavy,
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppDimensions.md),
                            Text(
                              'Pastikan password baru Anda minimal 8 karakter dan berbeda dari password sebelumnya.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppDimensions.fontDefault,
                                fontWeight: FontWeight.w500,
                                color: Colors.blueGrey.shade600,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.avatarMd),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: _buildFormCard(
                                  isAuthenticated,
                                  isLoading,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormCard(bool isAuthenticated, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xxl + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isAuthenticated) ...[
              _buildTextFieldLabel('Password Lama'),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _oldPassController,
                obscureText: !_isOldPassVisible,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.isEmpty
                    ? 'Password lama wajib diisi'
                    : null,
                decoration:
                    _inputDecoration(
                      hint: 'Masukkan Password Lama',
                      icon: AppIcons.lockKey,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isOldPassVisible ? AppIcons.eyeSlash : AppIcons.eye,
                          color: Colors.grey.shade500,
                          size: AppDimensions.iconDefault + 2,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isOldPassVisible = !_isOldPassVisible;
                          });
                        },
                      ),
                    ),
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
            _buildTextFieldLabel('Password Baru'),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              controller: _passController,
              obscureText: !_isPassVisible,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.isEmpty
                  ? 'Password baru wajib diisi'
                  : null,
              decoration:
                  _inputDecoration(
                    hint: 'Masukkan Password Baru',
                    icon: AppIcons.lockKey,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPassVisible ? AppIcons.eyeSlash : AppIcons.eye,
                        color: Colors.grey.shade500,
                        size: AppDimensions.iconDefault + 2,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isPassVisible = !_isPassVisible;
                        });
                      },
                    ),
                  ),
            ),
            const SizedBox(height: AppDimensions.md),
            _buildStrengthIndicator(),
            const SizedBox(height: AppDimensions.xl),
            _buildTextFieldLabel('Konfirmasi Password'),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              controller: _confirmPassController,
              obscureText: !_isConfirmPassVisible,
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitNewPassword(isAuthenticated),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Konfirmasi password tidak boleh kosong';
                }
                if (value != _passController.text) {
                  return 'Password tidak cocok!';
                }
                return null;
              },
              decoration:
                  _inputDecoration(
                    hint: 'Ulangi Password Baru',
                    icon: AppIcons.lockKey,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPassVisible
                            ? AppIcons.eyeSlash
                            : AppIcons.eye,
                        color: Colors.grey.shade500,
                        size: AppDimensions.iconDefault + 2,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isConfirmPassVisible = !_isConfirmPassVisible;
                        });
                      },
                    ),
                  ),
            ),
            const SizedBox(height: AppDimensions.xl),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => _submitNewPassword(isAuthenticated),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                elevation: 0,
              ),
              child: const Text(
                'SIMPAN PASSWORD',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg + 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: _primaryNavy.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kriteria Keamanan Password:',
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade700,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          _buildCriteriaRow('Minimal 8 Karakter', _hasMinLength),
          const SizedBox(height: AppDimensions.sm),
          _buildCriteriaRow('Harus Ada Huruf Kapital (A-Z)', _hasCapital),
          const SizedBox(height: AppDimensions.sm),
          _buildCriteriaRow('Harus Ada Angka (0-9)', _hasNumber),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(String label, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? AppIcons.checkCircleFill : AppIcons.circleFill,
          color: isValid ? Colors.green.shade600 : Colors.blueGrey.shade200,
          size: AppDimensions.iconSm,
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              fontWeight: isValid ? FontWeight.w600 : FontWeight.w500,
              color: isValid ? Colors.green.shade700 : Colors.blueGrey.shade500,
            ),
          ),
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

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.blueGrey.shade300,
        fontSize: AppDimensions.fontDefault,
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
