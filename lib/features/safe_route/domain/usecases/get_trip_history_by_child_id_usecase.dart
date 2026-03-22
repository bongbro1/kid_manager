import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/repositories/safe_route_repository.dart';

class GetTripHistoryByChildIdUseCase {
  const GetTripHistoryByChildIdUseCase(this._repository);

  final SafeRouteRepository _repository;

  Future<List<Trip>> call(String childId) {
    return _repository.getTripHistoryByChildId(childId);
  }
}
