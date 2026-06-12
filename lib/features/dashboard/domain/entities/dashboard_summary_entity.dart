final class DashboardSummaryEntity {
  final int totalSerdik;
  final int hadir;
  final int izin;
  final int absen;
  final double attendancePercentage;
  final double averageAcademic;
  final double averageMental;
  final double averagePhysical;
  final List<String> announcements;

  const DashboardSummaryEntity({
    required this.totalSerdik,
    required this.hadir,
    required this.izin,
    required this.absen,
    required this.attendancePercentage,
    required this.averageAcademic,
    required this.averageMental,
    required this.averagePhysical,
    required this.announcements,
  });
}
