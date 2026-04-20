import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/repositories/safe_route_repository.dart';

class WatchCurrentTripByChildIdUseCase {
  const WatchCurrentTripByChildIdUseCase(this._repository);

  final SafeRouteRepository _repository;

  Stream<Trip?> call(
    String childId, {
    required TripVisibilityAudience audience,
  }) {
    return _repository.watchCurrentTripByChildId(childId, audience: audience);
  }
}
