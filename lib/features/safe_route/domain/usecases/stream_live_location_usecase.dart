import 'package:kid_manager/features/safe_route/domain/entities/live_location.dart';
import 'package:kid_manager/features/safe_route/domain/repositories/safe_route_repository.dart';

class StreamLiveLocationUseCase {
  final SafeRouteRepository _repository;

  const StreamLiveLocationUseCase(this._repository);

  Stream<LiveLocation> call(String childId) {
    return _repository.streamLiveLocation(childId);
  }
}
