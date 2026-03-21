import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/repositories/safe_route_repository.dart';

class GetSuggestedRoutesUseCase {
  final SafeRouteRepository _repository;

  const GetSuggestedRoutesUseCase(this._repository);

  Future<List<SafeRoute>> call(
    RoutePoint start,
    RoutePoint end, {
    String? childId,
    required SafeRouteTravelMode travelMode,
  }) {
    return _repository.getSuggestedRoutes(
      start,
      end,
      childId: childId,
      travelMode: travelMode,
    );
  }
}
