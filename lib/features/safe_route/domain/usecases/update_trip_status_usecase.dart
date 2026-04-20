import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/repositories/safe_route_repository.dart';

class UpdateTripStatusUseCase {
  final SafeRouteRepository _repository;

  const UpdateTripStatusUseCase(this._repository);

  Future<void> call(String tripId, TripStatus status, {String? reason}) {
    return _repository.updateTripStatus(tripId, status, reason: reason);
  }
}
