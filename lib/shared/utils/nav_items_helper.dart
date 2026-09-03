import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

import '../../features/auth/presentation/pages/profile_screen.dart';
import '../../features/report/presentation/pages/report_screen.dart';
import '../../features/attendance/presentation/pages/attendance_screen.dart';
import '../../features/dashboard/presentation/pages/home_screen.dart';
import 'package:sespimma/features/assessment/presentation/pages/medis_health_monitoring_screen.dart';
import 'package:sespimma/features/assessment/presentation/pages/operator_jasmani_screen.dart';
import 'package:sespimma/features/assessment/presentation/pages/operator_sociometry_screen.dart';
import '../../features/attendance/presentation/pages/korsis_zone_screen.dart';
import 'package:sespimma/features/assessment/presentation/pages/monitoring_mental_screen.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}

List<NavItem> getNavItemsByRole(String roleId) {
  switch (roleId) {
    case 'pimpinan':
      return const [
        NavItem(
          label: 'Mental',
          icon: AppIcons.shieldCheck,
          activeIcon: AppIcons.shieldCheckFill,
          screen: MonitoringMentalScreen(),
        ),
        NavItem(
          label: 'Profil',
          icon: AppIcons.user,
          activeIcon: AppIcons.userFill,
          screen: ProfileScreen(),
        ),
      ];
    case 'gadik':
      return const [
        NavItem(
          label: 'Mental',
          icon: AppIcons.shieldCheck,
          activeIcon: AppIcons.shieldCheckFill,
          screen: MonitoringMentalScreen(),
        ),
        NavItem(
          label: 'Profil',
          icon: AppIcons.user,
          activeIcon: AppIcons.userFill,
          screen: ProfileScreen(),
        ),
      ];
    case 'patun':
      return const [
        NavItem(
          label: 'Mental',
          icon: AppIcons.shieldCheck,
          activeIcon: AppIcons.shieldCheckFill,
          screen: MonitoringMentalScreen(),
        ),
        NavItem(
          label: 'Profil',
          icon: AppIcons.user,
          activeIcon: AppIcons.userFill,
          screen: ProfileScreen(),
        ),
      ];
    case 'medis':
      return const [
        NavItem(
          label: 'Kesehatan',
          icon: Icons.monitor_heart_outlined,
          activeIcon: Icons.monitor_heart,
          screen: MedisHealthMonitoringScreen(),
        ),
        NavItem(
          label: 'Profil',
          icon: AppIcons.user,
          activeIcon: AppIcons.userFill,
          screen: ProfileScreen(),
        ),
      ];
    case 'korsis':
      return const [
        NavItem(
          label: 'Mental',
          icon: AppIcons.shieldCheck,
          activeIcon: AppIcons.shieldCheckFill,
          screen: MonitoringMentalScreen(),
        ),
        NavItem(
          label: 'Profil',
          icon: AppIcons.user,
          activeIcon: AppIcons.userFill,
          screen: ProfileScreen(),
        ),
      ];
    case 'operator':
      return const [
        NavItem(
          label: 'Jasmani',
          icon: Icons.directions_run_outlined,
          activeIcon: Icons.directions_run,
          screen: OperatorJasmaniScreen(),
        ),
        NavItem(
          label: 'Kesehatan',
          icon: Icons.monitor_heart_outlined,
          activeIcon: Icons.monitor_heart,
          screen: MedisHealthMonitoringScreen(),
        ),
        NavItem(
          label: 'Sosiometri',
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          screen: OperatorSociometryScreen(),
        ),
        NavItem(
          label: 'Zona',
          icon: AppIcons.mapPin,
          activeIcon: AppIcons.mapPinFill,
          screen: KorsisZoneScreen(),
        ),
        NavItem(
          label: 'Profil',
          icon: AppIcons.user,
          activeIcon: AppIcons.userFill,
          screen: ProfileScreen(),
        ),
      ];
    case 'siswa':
    default:
      return const [
        NavItem(
          label: 'Beranda',
          icon: AppIcons.house,
          activeIcon: AppIcons.houseFill,
          screen: HomeScreen(),
        ),
        NavItem(
          label: 'Absen',
          icon: Icons.qr_code_scanner_rounded,
          activeIcon: Icons.qr_code_scanner_rounded,
          screen: AttendanceScreen(),
        ),
        NavItem(
          label: 'Nilai',
          icon: AppIcons.chartBar,
          activeIcon: AppIcons.chartBarFill,
          screen: ReportScreen(),
        ),
        NavItem(
          label: 'Profil',
          icon: AppIcons.user,
          activeIcon: AppIcons.userFill,
          screen: ProfileScreen(),
        ),
      ];
  }
}
