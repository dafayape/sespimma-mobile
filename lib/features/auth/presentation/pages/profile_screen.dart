import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

import 'package:sespimma/shared/widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess) {
          final user = state.user;

          String title = 'Profil';

          return Scaffold(
            backgroundColor: _lightGrey,
            appBar: AppBar(
              backgroundColor: _primaryNavy,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppDimensions.fontXxl,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<AuthBloc>().add(const RefreshProfileRequested());
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildTopHeader(user),
                      Transform.translate(
                        offset: const Offset(0, -24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user.roleId != 'operator')
                                _buildStatCards(user),
                              if (user.roleId != 'kabag_bindik' &&
                                  user.roleId != 'medis' &&
                                  user.roleId != 'operator') ...[
                                const SizedBox(height: AppDimensions.lg),
                                _buildFormalDataCard(user),
                              ],
                              if (user.roleId == 'operator')
                                const SizedBox(height: 56)
                              else
                                const SizedBox(height: AppDimensions.xl),
                              _buildSectionTitle('PENGATURAN AKUN'),
                              const SizedBox(height: AppDimensions.md),
                              _buildSettingsCard(context),
                              const SizedBox(height: AppDimensions.xl),
                              _buildLogoutButton(context),
                              const SizedBox(height: AppDimensions.xl),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        }
        return const Scaffold(
          backgroundColor: _lightGrey,
          body: Center(child: CircularProgressIndicator(color: _primaryNavy)),
        );
      },
    );
  }

  String _getRoleLabel(UserEntity user) {
    if (user.roleId == 'patun') {
      return 'PERWIRA PENUNTUN';
    }
    if (user.roleId == 'korsis') {
      return 'KORSIS';
    }
    if (user.roleId == 'pimpinan') {
      return 'KASESPIMMA';
    }
    if (user.roleId == 'pimpinan') {
      return 'PIMPINAN';
    }
    if (user.roleId == 'patun') {
      return 'PATUN';
    }
    if (user.roleId == 'kabag_bindik') {
      return 'KABAG BINDIK';
    }
    if (user.roleId == 'korsis') {
      return 'KORSIS';
    }
    if (user.roleId == 'medis') {
      return 'MEDIS';
    }
    if (user.roleId == 'operator') {
      return 'OPERATOR';
    }
    if (user.roleId.startsWith('gadik')) {
      return 'TENAGA PENDIDIK';
    }
    return 'PESERTA DIDIK';
  }

  Color _getRoleBadgeColor(String roleId) {
    if (roleId == 'pimpinan') return const Color(0xFFFFAC1C);
    if (roleId == 'kabag_bindik') return const Color(0xFFC0392B);
    if (roleId == 'patun') return const Color(0xFF8E44AD);
    if (roleId == 'medis') return const Color(0xFF27AE60);
    if (roleId == 'korsis') return const Color(0xFF16A085);
    if (roleId == 'operator') return const Color(0xFF3498DB);
    if (roleId.startsWith('gadik')) return const Color(0xFF2980B9);
    return const Color(0xFF7F8C8D);
  }

  String _getFullPangkat(String pangkat) {
    if (pangkat.toUpperCase() == 'AKP') return 'AJUN KOMISARIS POLISI';
    return pangkat;
  }

  Widget _buildTopHeader(UserEntity user) {
    final roleLabel = _getRoleLabel(user);
    final badgeColor = _getRoleBadgeColor(user.roleId);

    return Container(
      width: double.infinity,
      color: _primaryNavy,
      padding: const EdgeInsets.only(bottom: 48, top: 20),
      child: Column(
        children: [
          _buildAvatar(user),
          const SizedBox(height: AppDimensions.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
            child: Text(
              user.roleId == 'operator'
                  ? 'TIM SESPIMMA'
                  : user.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppDimensions.fontXxl,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                color: badgeColor.withValues(alpha: 0.9),
                fontSize: AppDimensions.fontSm + 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            user.roleId == 'siswa' ? user.noSerdik : user.nrp,
            style: TextStyle(
              color: Colors.blueGrey.shade200,
              fontSize: AppDimensions.fontDefault,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserEntity user) {
    return UserAvatar(
      name: user.name,
      photoUrl: user.profilePhoto,
      size: 100,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildStatCards(UserEntity user) {
    final isSiswa = user.roleId == 'siswa';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildStatCard('PANGKAT', _getFullPangkat(user.pangkat)),
          ),
          const SizedBox(width: AppDimensions.md),
          if (isSiswa)
            Expanded(child: _buildStatCard('KELOMPOK', user.pokjar))
          else
            Expanded(
              child: _buildStatCard(
                (user.roleId == 'gadik' || user.roleId == 'patun' || user.roleId == 'korsis' || user.roleId == 'pimpinan')
                    ? 'JABATAN STRUKTURAL'
                    : 'JABATAN',
                user.jabatan,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppDimensions.fontSm + 1,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade400,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppDimensions.radiusSm),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormalDataCard(UserEntity user) {
    final isSiswa = user.roleId == 'siswa';

    List<Widget> rows;

    if (isSiswa) {
      final senatRole = user.displayJabatanSenat;
      rows = [
        if (senatRole != 'Tidak Ada' && senatRole.isNotEmpty)
          _buildDetailRow(AppIcons.starFill, 'JABATAN SENAT', senatRole),
        _buildDetailRow(AppIcons.medal, 'ANGKATAN', user.angkatan),
        _buildDetailRow(AppIcons.cake, 'UMUR', '${user.displayUmur} Tahun'),
        _buildDetailRow(
          AppIcons.identificationCard,
          'JENIS KELAMIN',
          user.displayJenisKelamin,
        ),
        _buildDetailRow(AppIcons.bookOpen, 'AGAMA', user.agama),
      ];
    } else if (user.roleId == 'gadik' || user.roleId == 'tenaga_pendidik') {
      rows = [
        _buildDetailRow(AppIcons.bookOpen, 'AGAMA', user.agama),
        _buildDetailRow(AppIcons.chartBar, 'ESELON', user.eselon),
        _buildDetailRow(AppIcons.chartBar, 'GOLONGAN', user.displayGolongan),
      ];
    } else if (user.roleId == 'patun') {
      rows = [
        _buildDetailRow(
          AppIcons.starFill,
          'JABATAN KEPANITIAAN',
          user.displayJabatanSenat,
        ),
        _buildDetailRow(
          AppIcons.usersFill,
          'POKJAR',
          user.pokjar.isNotEmpty && user.pokjar != '-' ? user.pokjar : 'POKJAR I',
        ),
      ];
    } else if (user.roleId == 'korsis' || user.roleId == 'pimpinan') {
      rows = [
        _buildDetailRow(
          AppIcons.starFill,
          'JABATAN KEPANITIAAN',
          user.displayJabatanSenat,
        ),
      ];
    } else if (user.roleId == 'medis') {
      rows = [
        _buildDetailRow(AppIcons.identificationCard, 'NRP/NIP', user.nrp),
        _buildDetailRow(AppIcons.user, 'NAMA LENGKAP', user.name),
        _buildDetailRow(
          AppIcons.medal,
          'PANGKAT',
          _getFullPangkat(user.pangkat),
        ),
        _buildDetailRow(AppIcons.clipboardText, 'JABATAN', user.jabatan),
      ];
    } else if (user.roleId == 'pimpinan' ||
        user.roleId == 'korsis' ||
        user.roleId == 'patun') {
      rows = [
        _buildDetailRow(AppIcons.identificationCard, 'NRP/NIP', user.nrp),
        _buildDetailRow(AppIcons.user, 'NAMA LENGKAP', user.name),
        _buildDetailRow(
          AppIcons.medal,
          'PANGKAT',
          _getFullPangkat(user.pangkat),
        ),
        _buildDetailRow(AppIcons.clipboardText, 'JABATAN', user.jabatan),
        if (user.jabatanSenat != '-')
          _buildDetailRow(
            AppIcons.starFill,
            'PERAN PENGASUHAN',
            user.jabatanSenat,
          ),
      ];
    } else {
      rows = [
        _buildDetailRow(
          AppIcons.identificationCard,
          'NO SERDIK',
          user.noSerdik,
        ),
        _buildDetailRow(AppIcons.user, 'NAMA LENGKAP', user.name),
        _buildDetailRow(AppIcons.mapPin, 'TEMPAT LAHIR', user.tempatLahir),
        _buildDetailRow(
          AppIcons.calendarBlank,
          'TANGGAL LAHIR',
          user.tanggalLahir ?? '-',
        ),
        _buildDetailRow(AppIcons.cake, 'UMUR', '${user.displayUmur} Tahun'),
        _buildDetailRow(
          AppIcons.identificationCard,
          'JENIS KELAMIN',
          user.jenisKelamin,
        ),
        _buildDetailRow(AppIcons.bookOpen, 'AGAMA', user.agama),
        _buildDetailRow(
          AppIcons.deviceMobileSpeakerFill,
          'NO TELEPON',
          user.noTelepon,
        ),
        _buildDetailRow(
          AppIcons.bookOpen,
          'PENDIDIKAN TERAKHIR',
          user.pendidikanTerakhir,
        ),
        _buildDetailRow(AppIcons.mapPin, 'ALAMAT LENGKAP', user.alamatLengkap),
        _buildDetailRow(AppIcons.paperPlaneTiltFill, 'EMAIL', user.email),
        _buildDetailRow(
          AppIcons.deviceMobileSpeakerFill,
          'NO TELEPON',
          user.noTelepon,
        ),
        _buildDetailRow(AppIcons.usersFill, 'KELOMPOK', user.pokjar),
        _buildDetailRow(AppIcons.bookOpen, 'DIKTUK AWAL', user.diktukAwal),
        _buildDetailRow(
          AppIcons.calendarBlank,
          'TAHUN DIKTUK',
          user.tahunDiktuk,
        ),
        _buildDetailRow(AppIcons.user, 'PERSONEL POLRI', user.displayPersonel),
        _buildDetailRow(AppIcons.identificationCard, 'NRP', user.nrp),
        _buildDetailRow(
          AppIcons.medal,
          'PANGKAT',
          _getFullPangkat(user.pangkat),
        ),
        _buildDetailRow(AppIcons.starFill, 'JABATAN SENAT', user.displayJabatanSenat),
        _buildDetailRow(AppIcons.clipboardText, 'JABATAN', user.jabatan),
        _buildDetailRow(AppIcons.buildingsFill, 'SATKER', user.satker),
      ];
    }

    List<Widget> children = [];
    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(
          Divider(height: 1, color: Colors.grey.shade100, indent: 64),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg + 2),
            ),
            child: Icon(icon, color: _primaryNavy, size: AppDimensions.iconLg),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm + 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey.shade400,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontLg + 1,
                    fontWeight: FontWeight.w700,
                    color: _primaryNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppDimensions.fontMd,
        fontWeight: FontWeight.w800,
        color: Colors.blueGrey.shade400,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(
            context,
            AppIcons.user,
            'Edit Profil',
            () => Navigator.pushNamed(context, '/edit-profile'),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _buildMenuTile(
            context,
            AppIcons.lockKey,
            'Ubah Password',
            () => Navigator.pushNamed(context, '/reset-password'),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _buildMenuTile(
            context,
            AppIcons.question,
            'Bantuan',
            () => Navigator.pushNamed(context, '/help-faq'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: _primaryNavy, size: AppDimensions.iconLg),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w600,
            color: _primaryNavy,
          ),
        ),
        trailing: Icon(AppIcons.caretRight, color: Colors.grey.shade400),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.heavyImpact();
          _showLogoutConfirmationSheet(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
        icon: const Icon(AppIcons.signOut, size: AppDimensions.iconDefault + 2),
        label: const Text(
          'Keluar',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontLg,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationSheet(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final navigator = Navigator.of(context);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMd + 2,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.warningCircleFill,
                  color: Colors.red.shade600,
                  size: AppDimensions.avatarMd,
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              const Text(
                'Konfirmasi Keluar',
                style: TextStyle(
                  fontSize: AppDimensions.fontXxl,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                'Apakah Anda yakin ingin keluar dari aplikasi SESPIMMA? Sesi login Anda akan berakhir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDimensions.fontDefault,
                  color: Colors.blueGrey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(sheetContext);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.blueGrey.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: AppDimensions.fontLg,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        authBloc.add(const LogoutRequested());
                        navigator.pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Ya, Keluar',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: AppDimensions.fontLg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  }
}
