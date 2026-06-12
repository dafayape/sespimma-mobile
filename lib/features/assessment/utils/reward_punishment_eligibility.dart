import 'package:sespimma/core/constants/reward_punishment_data.dart';
import 'package:sespimma/features/assessment/data/models/korsis_inbox_mock_data.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';

class EligibilityStatus {
  final bool isEligible;
  final String? message;

  EligibilityStatus(this.isEligible, [this.message]);
}

class RewardPunishmentEligibility {
  static EligibilityStatus checkEligibility(
    String nosis,
    RewardPunishmentItem item,
  ) {
    final history = KorsisInboxMockData.items
        .where((i) => i.nosis == nosis)
        .toList();

    if (['R_M_04', 'R_M_05', 'R_M_06', 'R_M_07'].contains(item.id)) {
      int count = history.where((i) => i.rewardPunishmentId == item.id).length;
      if (count >= 3) {
        return EligibilityStatus(
          false,
          "Batas maksimal (3x) sudah tercapai untuk reward ini",
        );
      }
    }

    if (item.id == 'R_K_05') {
      final now = DateTime.now();

      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      int count = history.where((i) {
        return i.rewardPunishmentId == item.id &&
            i.timestamp.isAfter(weekStart);
      }).length;

      if (count >= 2) {
        return EligibilityStatus(
          false,
          "Batas maksimal (2x/minggu) sudah tercapai minggu ini",
        );
      }
    }

    if (item.id == 'R_D_01') {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));
      bool hasPunishment = history.any((i) {
        return i.rewardPunishmentId != null &&
            i.rewardPunishmentId!.startsWith('P_D_') &&
            i.timestamp.isAfter(monthAgo);
      });

      if (hasPunishment) {
        return EligibilityStatus(
          false,
          "Serdik memiliki catatan pelanggaran disiplin dalam 30 hari terakhir",
        );
      }
    }

    final bool isSenat = _isSenat(nosis);

    if (item.id == 'R_K_01') {
      if (!isSenat) {
        return EligibilityStatus(
          false,
          "Reward ini khusus untuk perangkat senat",
        );
      }
    }

    if (item.id == 'R_D_03') {
      if (isSenat) {
        return EligibilityStatus(
          false,
          "Reward ini hanya untuk serdik non-senat",
        );
      }
    }

    return EligibilityStatus(true);
  }

  static bool _isSenat(String nosis) {
    final serdik = SerdikRealData.records.firstWhere(
      (s) => s['no_serdik'] == nosis,
      orElse: () => {},
    );

    if (serdik.isNotEmpty) {
      if (serdik['jabatan'] != null &&
          serdik['jabatan'].toString().toLowerCase().contains('senat')) {
        return true;
      }
    }

    return nosis.endsWith('1');
  }
}
