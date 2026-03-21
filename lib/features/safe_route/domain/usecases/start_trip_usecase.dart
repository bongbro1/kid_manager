import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/repositories/safe_route_repository.dart';

class StartTripUseCase {
  final SafeRouteRepository _repository;

  const StartTripUseCase(this._repository);

  Future<Trip> call(Trip trip) {
    return _repository.startTrip(trip);
  }
}
