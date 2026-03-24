import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kid_manager/features/safe_route/presentation/child_safe_route_guidance.dart';
import 'package:kid_manager/features/safe_route/presentation/states/child_safe_route_state.dart';
import 'package:kid_manager/features/safe_route/presentation/widgets/child_safe_route_hud.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/location_data.dart';

void main() {
  testWidgets('renders safely in compact height without overflow', (
    tester,
  ) async {
    final state = ChildSafeRouteState.initial('child-1').copyWith(
      currentLocation: LocationData.fromDateTime(
        latitude: 21.0,
        longitude: 105.0,
        accuracy: 5,
        dateTime: DateTime.now(),
      ),
      guidance: const ChildSafeRouteGuidance(
        severity: ChildSafeRouteSeverity.safe,
        primaryInstruction: 'Tiếp tục đi thẳng thêm 120 m',
        secondaryInstruction: 'Con đang đi đúng đường an toàn đã chọn.',
        statusLabel: 'An toàn',
        remainingDistanceLabel: '120 m',
        etaLabel: '2 phút',
        remainingDistanceMeters: 120,
        distanceFromRouteMeters: 4,
        progress: 0.65,
        triggeredHazard: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 220,
              child: Stack(
                children: [
                  ChildSafeRouteHud(
                    state: state,
                    languageCode: 'vi',
                    topOffset: 12,
                    bottomOffset: 12,
                    showBottomStatusPill: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tiếp tục đi thẳng thêm 120 m'), findsOneWidget);
    expect(find.text('An toàn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
