import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:url_launcher/url_launcher.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);
  static const Color _waColor = Color(0xFF25D366);

  static const String _adminWaNumber = '6285862393696';
  static const String _adminWaText =
      'Halo Admin Makerindo, saya di akun SESPIMMA ingin meminta token reset password.';
  static const String _validResetToken = 'MAKERINDO75';

  bool _isLoading = false;
  String? _nrp;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nrp = ModalRoute.of(context)?.settings.arguments as String?;
  }

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _contactAdminWA() async {
    final String encodedText = Uri.encodeComponent(_adminWaText);
    final Uri url = Uri.parse(
      'https://wa.me/$_adminWaNumber?text=$encodedText',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(
          context,
          'Gagal membuka WhatsApp. Pastikan aplikasi terinstal.',
        );
      }
    }
  }

  Future<void> _verifyToken() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (_tokenController.text.trim() == _validResetToken) {
        Navigator.pushReplacementNamed(
          context,
          '/reset-password',
          arguments: _nrp,
        );
      } else {
        AppNotifier.showError(context, 'Token verifikasi tidak valid!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _lightGrey,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.caretLeft, size: AppDimensions.iconXl),
          color: _primaryNavy,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Lupa Password',
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
                    padding: const EdgeInsets.all(AppDimensions.xl - 4),
                    decoration: BoxDecoration(
                      color: _primaryNavy.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.lockKey,
                      size: AppDimensions.iconDisplay,
                      color: _primaryNavy,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  const Text(
                    'Verifikasi Identitas',
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
                    'Demi keamanan data akun Anda, silakan hubungi Admin PT. Makerindo Prima Solusi untuk mendapatkan Token Verifikasi Anda.',
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
                      child: _buildFormCard(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _contactAdminWA,
        backgroundColor: _waColor,
        elevation: 4,
        icon: Icon(AppIcons.whatsappLogoFill, color: Colors.white),
        label: const Text(
          'Hubungi Admin',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
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
            Text(
              'Token Verifikasi',
              style: TextStyle(
                fontSize: AppDimensions.fontDefault,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              controller: _tokenController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _verifyToken(),
              validator: (value) => value == null || value.isEmpty
                  ? 'Token tidak boleh kosong'
                  : null,
              decoration: InputDecoration(
                hintText: 'Masukkan Token Anda',
                hintStyle: TextStyle(
                  color: Colors.blueGrey.shade300,
                  fontSize: AppDimensions.fontLg,
                ),
                prefixIcon: Icon(
                  AppIcons.key,
                  color: Colors.blueGrey.shade400,
                  size: AppDimensions.iconDefault + 2,
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
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
              ),
            ),
            const SizedBox(height: AppDimensions.xxl + 4),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'VERIFIKASI',
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
}
