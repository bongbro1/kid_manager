import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/repositories/safe_route_repository.dart';

class GetRouteByIdUseCase {
  final SafeRouteRepository _repository;

  const GetRouteByIdUseCase(this._repository);

  Future<SafeRoute?> call(String routeId) {
    return _repository.getRouteById(routeId);
  }
}
