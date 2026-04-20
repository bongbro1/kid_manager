import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/repositories/safe_route_repository.dart';

class GetActiveTripByChildIdUseCase {
  final SafeRouteRepository _repository;

  const GetActiveTripByChildIdUseCase(this._repository);

  Future<Trip?> call(String childId) {
    return _repository.getActiveTripByChildId(childId);
  }
}
