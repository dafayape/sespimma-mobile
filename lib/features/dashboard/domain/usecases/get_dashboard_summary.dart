import 'package:sespimma/core/usecases/usecase.dart';
import '../entities/dashboard_summary_entity.dart';
import '../repositories/dashboard_repository.dart';

final class GetDashboardSummary
    implements UseCase<DashboardSummaryEntity, NoParams> {
  final DashboardRepository _repository;
  const GetDashboardSummary(this._repository);

  @override
  Future<DashboardSummaryEntity> call(NoParams params) =>
      _repository.getDashboardSummary();
}
