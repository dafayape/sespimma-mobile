import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class SerdikInfoHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> serdik;
  final String golongan;
  final String gender;

  const SerdikInfoHeaderWidget({
    super.key,
    required this.serdik,
    required this.golongan,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final name = (serdik['nama_lengkap'] ?? '-').toString();
    final noSerdik = (serdik['no_serdik'] ?? '-').toString();
    final pangkat = (serdik['pangkat'] ?? '-').toString();
    final hasPhoto =
        serdik['foto'] != null && serdik['foto'].toString().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              image: DecorationImage(
                image: hasPhoto
                    ? NetworkImage(serdik['foto'].toString()) as ImageProvider
                    : AvatarHelper.getAvatar(null),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$pangkat · $noSerdik',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        golongan,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (gender.toLowerCase() == 'pria' ||
                                gender.toLowerCase() == 'laki-laki')
                            ? Colors.blue.shade100
                            : Colors.pink.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (gender.toLowerCase() == 'pria' ||
                                    gender.toLowerCase() == 'laki-laki')
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            size: 12,
                            color:
                                (gender.toLowerCase() == 'pria' ||
                                    gender.toLowerCase() == 'laki-laki')
                                ? Colors.blue.shade900
                                : Colors.pink.shade900,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (gender.toLowerCase() == 'pria' ||
                                    gender.toLowerCase() == 'laki-laki')
                                ? 'Pria'
                                : 'Wanita',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color:
                                  (gender.toLowerCase() == 'pria' ||
                                      gender.toLowerCase() == 'laki-laki')
                                  ? Colors.blue.shade900
                                  : Colors.pink.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
