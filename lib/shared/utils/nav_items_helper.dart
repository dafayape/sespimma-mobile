import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

import '../../features/auth/presentation/pages/profile_screen.dart';
import '../../features/report/presentation/pages/report_screen.dart';
import '../../features/attendance/presentation/pages/attendance_screen.dart';
import '../../features/dashboard/presentation/pages/home_screen.dart';
import 'package:sespimma/features/assessment/presentation/pages/medis_health_monitoring_screen.dart';
import 'package:sespimma/features/assessment/presentation/pages/operator_jasmani_screen.dart';
import '../../features/assessment/presentation/pages/patun_physical_monitoring_screen.dart';
import '../../features/assessment/presentation/pages/korsis_inbox_screen.dart';
import '../../features/assessment/presentation/pages/korsis_mental_monitoring_screen.dart';
import '../../features/assessment/presentation/pages/patun_mental_monitoring_screen.dart';
import '../../features/assessment/presentation/pages/gadik_assessment_screen.dart';

import '../../features/leadership_dashboard/presentation/pages/pimpinan_home_screen.dart';
import '../../features/attendance/presentation/pages/pimpinan_attendance_monitoring_screen.dart';
import '../../features/attendance/presentation/pages/patun_attendance_monitoring_screen.dart';
import '../../features/attendance/presentation/pages/korsis_zone_screen.dart';

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
          label: 'Beranda',
          icon: AppIcons.house,
          activeIcon: AppIcons.houseFill,
          screen: PimpinanHomeScreen(),
        ),
        NavItem(
          label: 'Absen',
          icon: AppIcons.mapPin,
          activeIcon: AppIcons.mapPinFill,
          screen: PimpinanAttendanceMonitoringScreen(),
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
          label: 'Penilaian',
          icon: AppIcons.shieldCheck,
          activeIcon: AppIcons.shieldCheckFill,
          screen: GadikAssessmentScreen(),
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
          screen: PatunMentalMonitoringScreen(),
        ),
        NavItem(
          label: 'Jasmani',
          icon: AppIcons.barbellFill,
          activeIcon: AppIcons.barbellFill,
          screen: PatunPhysicalMonitoringScreen(),
        ),
        NavItem(
          label: 'Absen',
          icon: AppIcons.mapPin,
          activeIcon: AppIcons.mapPinFill,
          screen: PatunAttendanceMonitoringScreen(),
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
          label: 'Inbox',
          icon: AppIcons.archive,
          activeIcon: AppIcons.archive,
          screen: KorsisInboxScreen(),
        ),
        NavItem(
          label: 'Mental',
          icon: AppIcons.shieldCheck,
          activeIcon: AppIcons.shieldCheckFill,
          screen: KorsisMentalMonitoringScreen(),
        ),
        NavItem(
          label: 'Jasmani',
          icon: AppIcons.barbellFill,
          activeIcon: AppIcons.barbellFill,
          screen: PatunPhysicalMonitoringScreen(),
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
          label: 'Zona',
          icon: AppIcons.mapPin,
          activeIcon: AppIcons.mapPinFill,
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
