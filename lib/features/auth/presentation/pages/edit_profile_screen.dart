import 'package:sespimma/core/constants/app_dimensions.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';
import 'package:sespimma/shared/widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isPhotoRemoved = false;
  bool _isInitialized = false;

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

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (file != null) {
        setState(() {
          _selectedImage = File(file.path);
          _isPhotoRemoved = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removePhoto() {
    Navigator.pop(context);
    setState(() {
      _selectedImage = null;
      _isPhotoRemoved = true;
    });
  }

  String _getFullPangkat(String pangkat) {
    if (pangkat.toUpperCase() == 'AKP') return 'AJUN KOMISARIS POLISI';
    return pangkat;
  }

  void _showImagePickerOptions(UserEntity? user) {
    final bool hasPhoto =
        _selectedImage != null ||
        (!_isPhotoRemoved && (user?.profilePhoto != null && user!.profilePhoto!.trim().isNotEmpty));

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(AppDimensions.xs / 2),
                  ),
                ),
                const Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: AppDimensions.fontXxl,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
                _buildBottomSheetTile(
                  icon: AppIcons.camera,
                  title: 'Ambil dari Kamera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildBottomSheetTile(
                  icon: AppIcons.image,
                  title: 'Pilih dari Galeri',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                if (hasPhoto)
                  _buildBottomSheetTile(
                    icon: AppIcons.trash,
                    title: 'Hapus Foto',
                    color: Colors.red.shade600,
                    onTap: _removePhoto,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: (color ?? _primaryNavy).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color ?? _primaryNavy,
            size: AppDimensions.iconLg,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color ?? _primaryNavy,
            fontSize: AppDimensions.fontLg + 1,
          ),
        ),
        trailing: Icon(AppIcons.caretRight, color: Colors.grey.shade400),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }

  void _saveChanges() {
    HapticFeedback.heavyImpact();

    if (_selectedImage != null && _selectedImage!.existsSync()) {
      context.read<AuthBloc>().add(
        UpdateProfilePhotoRequested(_selectedImage!.path),
      );
      AppNotifier.showSuccess(context, 'Foto profil berhasil diperbarui');
    } else if (_isPhotoRemoved) {
      context.read<AuthBloc>().add(
        const UpdateProfilePhotoRequested(null),
      );
      AppNotifier.showSuccess(context, 'Foto profil berhasil dihapus');
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthSuccess ? state.user : null;

        if (user != null && !_isInitialized) {
          _isInitialized = true;
        }

        return Scaffold(
          backgroundColor: _lightGrey,
          appBar: AppBar(
            backgroundColor: _lightGrey,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(AppIcons.caretLeft, size: AppDimensions.iconXl),
              onPressed: () => Navigator.pop(context),
              color: _primaryNavy,
            ),
            title: const Text(
              'Edit Profil',
              style: TextStyle(
                color: _primaryNavy,
                fontWeight: FontWeight.w800,
                fontSize: AppDimensions.fontXxl,
              ),
            ),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<AuthBloc>().add(const RefreshProfileRequested());
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildProfileAvatar(user),
                          const SizedBox(height: AppDimensions.xl),
                          const Text(
                            'Ketuk ikon kamera di atas untuk mengubah\nfoto profil resmi Anda.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppDimensions.fontDefault,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.xl),
                          _buildIdentityCard(user),
                          const SizedBox(height: AppDimensions.avatarMd),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildProfileAvatar(UserEntity? user) {
    return Center(
      child: GestureDetector(
        onTap: () => _showImagePickerOptions(user),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            UserAvatar(
              name: user?.name,
              photoUrl: _isPhotoRemoved ? null : user?.profilePhoto,
              localFile: _selectedImage,
              size: 140,
              borderRadius: BorderRadius.circular(70),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: _primaryNavy,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                AppIcons.cameraFill,
                color: Colors.white,
                size: AppDimensions.iconDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryNavy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          ),
          elevation: 4,
          shadowColor: _primaryNavy.withValues(alpha: 0.4),
        ),
        child: const Text(
          'SIMPAN PERUBAHAN',
          style: TextStyle(
            fontSize: AppDimensions.fontLg + 1,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityCard(UserEntity? user) {
    if (user == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: _primaryNavy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(
                  AppIcons.identificationCardFill,
                  color: _primaryNavy,
                  size: AppDimensions.iconDefault,
                ),
              ),
              const SizedBox(width: AppDimensions.md - 4),
              const Text(
                'Informasi Akademik Resmi',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg + 1,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                ),
              ),
            ],
          ),
          const Divider(height: 32, thickness: 1),
          if (user.roleId == 'siswa') ...[
            _buildInfoRow('No. Serdik', user.noSerdik),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Nama Lengkap', user.name),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Alamat Lengkap', user.alamatLengkap),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Tempat Lahir', user.tempatLahir),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jenis Kelamin', user.displayJenisKelamin),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Agama', user.agama),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Email', user.email),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('No. Telepon', user.noTelepon),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Pendidikan Terakhir', user.pendidikanTerakhir),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Kelompok', user.pokjar),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Diktuk Awal', user.diktukAwal),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Tahun Diktuk', user.tahunDiktuk),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Personel Polri', user.displayPersonel),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('NRP', user.nrp),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Pangkat', _getFullPangkat(user.pangkat)),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jabatan Senat', user.displayJabatanSenat),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jabatan', user.jabatan),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Satker', user.satker),
          ] else if (user.roleId == 'medis') ...[
            _buildInfoRow(user.nrp.length > 10 ? 'NIP' : 'NRP', user.nrp),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Nama Lengkap', user.name),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Pangkat', _getFullPangkat(user.pangkat)),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jabatan', user.jabatan),
          ] else if (user.roleId == 'operator') ...[
            _buildInfoRow('NRP', user.nrp),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Nama Lengkap', user.name),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jabatan', 'Operator'),
          ] else if (user.roleId == 'patun') ...[
            _buildInfoRow(user.nrp.length > 10 ? 'NIP' : 'NRP', user.nrp),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Nama Lengkap', user.name),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Pangkat', _getFullPangkat(user.pangkat)),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jabatan Struktural', user.jabatan),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jabatan Kepanitiaan', user.displayJabatanSenat),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Pokjar', user.pokjar.isNotEmpty && user.pokjar != '-' ? user.pokjar : 'POKJAR I'),
          ] else if (user.roleId == 'korsis' ||
              user.roleId == 'pimpinan' ||
              user.roleId == 'kabag_bindik') ...[
            _buildInfoRow(user.nrp.length > 10 ? 'NIP' : 'NRP', user.nrp),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Nama Lengkap', user.name),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Pangkat', _getFullPangkat(user.pangkat)),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jabatan Struktural', user.jabatan),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jabatan Kepanitiaan', user.displayJabatanSenat),
          ] else if (user.roleId == 'gadik') ...[
            _buildInfoRow(user.nrp.length > 10 ? 'NIP' : 'NRP', user.nrp),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Nama Lengkap', user.name),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Agama', user.agama),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Pangkat', _getFullPangkat(user.pangkat)),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jabatan Struktural', user.jabatan),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Eselon', user.eselon),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Golongan', user.displayGolongan),
          ] else ...[
            _buildInfoRow(user.nrp.length > 10 ? 'NIP' : 'NRP', user.nrp),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Nama Lengkap', user.name),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Pangkat', _getFullPangkat(user.pangkat)),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Jabatan', user.jabatan),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('Email', user.email),
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow('No. Handphone', user.noHandphone),
          ],
          const Divider(height: 32, thickness: 1),
          Row(
            children: [
              Icon(
                AppIcons.infoFill,
                color: Colors.blueGrey.shade300,
                size: AppDimensions.iconSm,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  'Data akademik di atas bersifat permanen dan hanya dapat diubah oleh Administrator.',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm + 1,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade400,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade400,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          value.isNotEmpty ? value : '-',
          style: const TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w700,
            color: _primaryNavy,
          ),
        ),
      ],
    );
  }
}
