import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/assessment/data/models/korsis_inbox_mock_data.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class PatunSenatValidationSheet extends StatefulWidget {
  final List<Map<String, dynamic>> pokjarMembers;

  const PatunSenatValidationSheet({super.key, required this.pokjarMembers});

  @override
  State<PatunSenatValidationSheet> createState() =>
      _PatunSenatValidationSheetState();
}

class _PatunSenatValidationSheetState extends State<PatunSenatValidationSheet> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  final Map<String, bool> _approvalStatus = {};

  List<Map<String, dynamic>> _senatMembers = [];

  @override
  void initState() {
    super.initState();

    _senatMembers = widget.pokjarMembers
        .where(
          (m) =>
              m['jabatan_senat'] != null &&
              m['jabatan_senat'].toString().isNotEmpty,
        )
        .toList();
    if (_senatMembers.isEmpty) {
      _senatMembers = widget.pokjarMembers.take(3).toList();
    }
    for (var member in _senatMembers) {
      _approvalStatus[member['no_serdik']] = true;
    }
  }

  void _submitValidation() {
    final now = DateTime.now();
    for (var member in _senatMembers) {
      final id = member['no_serdik'] as String;
      final isApproved = _approvalStatus[id] ?? false;

      if (isApproved) {
        KorsisInboxMockData.addRecord(
          InboxItem(
            id: 'senat_val_${DateTime.now().millisecondsSinceEpoch}_$id',
            serdikName: member['nama_lengkap'] ?? '-',
            pangkat: member['pangkat'] ?? '-',
            nosis: member['no_serdik'] ?? '-',
            pokjar: member['kelompok_kelas'] ?? '-',
            isReward: true,
            senderName: 'Sistem (Validasi Patun)',
            timestamp: now,
            points: 0.25,
            description: 'Validasi keaktifan senat disetujui oleh Patun.',
            rewardPunishmentName: 'Validasi Keaktifan Senat',
            status: 'approved',
          ),
        );
      }
    }

    Navigator.pop(context, true);
    AppNotifier.showSuccess(
      context,
      'Validasi reward senat berhasil dikirim ke Inbox Korsis.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: _lightGrey,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.xl),
              physics: const BouncingScrollPhysics(),
              itemCount: _senatMembers.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppDimensions.md),
              itemBuilder: (context, index) {
                final member = _senatMembers[index];
                final id = member['no_serdik'] as String;
                final isApproved = _approvalStatus[id] ?? false;
                final role = member['jabatan_senat'] ?? 'Anggota Senat';

                return _buildSenatCard(member, role, isApproved, id);
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Validasi Reward Senat',
                  style: TextStyle(
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review keaktifan senat untuk pemberian +0.25 poin.',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
            color: Colors.grey.shade600,
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSenatCard(
    Map<String, dynamic> member,
    String role,
    bool isApproved,
    String id,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isApproved ? Colors.green.shade300 : Colors.grey.shade300,
          width: isApproved ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              shape: BoxShape.circle,
              image: DecorationImage(
                image:
                    (member['profile_photo'] != null &&
                        member['profile_photo'].toString().isNotEmpty)
                    ? FileImage(File(member['profile_photo'])) as ImageProvider
                    : AvatarHelper.getAvatar(null),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['nama_lengkap'] ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: AppDimensions.fontMd,
                    color: _primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${member['pangkat'] ?? '-'} · ${member['no_serdik'] ?? '-'}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 10,
                        color: Color(0xFF1A237E),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontXs,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A237E),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          GestureDetector(
            onTap: () {
              setState(() {
                _approvalStatus[id] = !isApproved;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isApproved ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isApproved
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isApproved
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isApproved ? Colors.green.shade700 : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+0.25',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isApproved ? Colors.green.shade700 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: _submitValidation,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryNavy,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            elevation: 0,
          ),
          child: const Text(
            'SETUJU',
            style: TextStyle(
              fontSize: AppDimensions.fontLg,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
