class TrackingTuning {
  const TrackingTuning._();

  static const double goodAccuracyMaxM = 15.0;
  static const double moderateAccuracyMaxM = 30.0;
  static const double weakAccuracyMaxM = 50.0;
  static const double historyGoodAccuracyMaxM = 30.0;
  static const double currentRejectAccuracyMaxM = 100.0;
  static const double jumpGuardBadAccuracyMinM = 20.0;
  static const double currentGoodAccuracyMaxM = 20.0;
  static const double currentModerateAccuracyMaxM = 50.0;

  static const Duration motionIdleDelay = Duration(seconds: 45);
  static const Duration motionStationaryDelay = Duration(minutes: 3);
  static const double motionBaseMovementThresholdGoodKm = 0.006;
  static const double motionBaseMovementThresholdModerateKm = 0.010;
  static const double motionBaseMovementThresholdWeakKm = 0.016;
  static const double motionBaseMovementThresholdFallbackKm = 0.020;
  static const double motionIdleDistanceMultiplier = 1.5;
  static const double motionStationaryDistanceMultiplier = 2.2;
  static const double motionMovingSpeedThresholdMovingMps = 0.85;
  static const double motionMovingSpeedThresholdIdleGoodMps = 1.15;
  static const double motionMovingSpeedThresholdIdleWeakMps = 1.45;
  static const double motionMovingSpeedThresholdStationaryGoodMps = 1.35;
  static const double motionMovingSpeedThresholdStationaryWeakMps = 1.75;

  static const int indoorSuppressionEntryStreak = 3;
  static const double indoorSuppressionLowAccuracyMinM = 18.0;
  static const double indoorSuppressionMaxAccuracyM = 50.0;
  static const double indoorSuppressionLowRawSpeedMaxMps = 0.6;
  static const double indoorSuppressionLowResolvedSpeedMaxMps = 1.8;
  static const double indoorSuppressionNoiseRadiusMinM = 18.0;
  static const double indoorSuppressionNoiseRadiusMultiplier = 1.6;
  static const double indoorSuppressionAnchorRefreshRadiusM = 6.0;
  static const double indoorSuppressionReleaseGoodFixAccuracyMaxM = 12.0;
  static const double indoorSuppressionReleaseGoodFixSpeedMinMps = 0.9;
  static const int indoorSuppressionReleaseGoodFixStreak = 2;
  static const double indoorSuppressionReleaseDistanceMinM = 16.0;
  static const double indoorSuppressionReleaseDistanceMultiplier = 1.2;
  static const Duration indoorDriftMaxReferenceAge = Duration(seconds: 30);
  static const double indoorDriftStrictNoiseRadiusMinM = 6.0;
  static const double indoorDriftStrictNoiseRadiusMultiplier = 1.25;
  static const double indoorDriftStickyIdleNoiseRadiusMinM = 18.0;
  static const double indoorDriftStickyStationaryNoiseRadiusMinM = 24.0;
  static const double indoorDriftStickyStationaryNoiseRadiusMultiplier = 2.0;
  static const double indoorDriftAccuracyEnvelopeMinAccuracyM = 12.0;
  static const double indoorDriftAccuracyEnvelopeRawSpeedMaxMps = 0.55;
  static const double indoorDriftStickyRawSpeedMaxMps = 0.35;
  static const double indoorDriftStickyResolvedSpeedMaxMps = 2.2;
  static const double stableAnchorIdleMaxDriftMinM = 15.0;
  static const double stableAnchorIdleDriftMultiplier = 1.4;
  static const double stableAnchorStationaryMaxDriftMinM = 20.0;
  static const double stableAnchorStationaryDriftMultiplier = 1.8;

  static const double weakGpsKeepAliveAccuracyM = 80.0;
  static const Duration weakGpsKeepAliveInterval = Duration(minutes: 2);
  static const double moderateGpsKeepAliveAccuracyM = 50.0;
  static const Duration moderateGpsKeepAliveInterval = Duration(minutes: 1);
  static const double turnSendThresholdDeg = 25.0;
  static const Duration nightKeepAliveInterval = Duration(minutes: 5);
  static const double nightMovingDistanceKm = 0.1;
  static const Duration walkingMovingInterval = Duration(seconds: 10);
  static const double walkingMovingDistanceKm = 0.012;
  static const Duration bicycleMovingInterval = Duration(seconds: 7);
  static const double bicycleMovingDistanceKm = 0.015;
  static const Duration vehicleMovingInterval = Duration(seconds: 5);
  static const double vehicleMovingDistanceKm = 0.020;
  static const Duration unknownMovingInterval = Duration(seconds: 10);
  static const double unknownMovingDistanceKm = 0.015;
  static const double stillUnknownWeakAccuracyMinM = 30.0;
  static const Duration stillUnknownWeakInterval = Duration(seconds: 20);
  static const double stillUnknownWeakDistanceKm = 0.025;
  static const double stillUnknownTightDistanceKm = 0.018;
  static const double idleHistoryDistanceKm = 0.02;
  static const Duration idleHistoryKeepAliveInterval = Duration(minutes: 2);
  static const Duration stationaryHistoryKeepAliveInterval =
      Duration(minutes: 5);

  static const Duration currentMovingGoodInterval = Duration(seconds: 5);
  static const Duration currentMovingModerateInterval = Duration(seconds: 10);
  static const Duration currentMovingWeakInterval = Duration(seconds: 20);
  static const Duration currentIdleGoodInterval = Duration(seconds: 45);
  static const Duration currentIdleModerateInterval = Duration(minutes: 1);
  static const Duration currentIdleWeakInterval = Duration(minutes: 2);
  static const Duration currentStationaryGoodInterval = Duration(minutes: 2);
  static const Duration currentStationaryModerateInterval =
      Duration(minutes: 3);
  static const Duration currentStationaryWeakInterval = Duration(minutes: 5);

  static const double suppressedCurrentKeepAliveAcc20MaxM = 20.0;
  static const double suppressedCurrentKeepAliveAcc35MaxM = 35.0;
  static const Duration suppressedCurrentKeepAliveAcc20 =
      Duration(minutes: 2);
  static const Duration suppressedCurrentKeepAliveAcc35 =
      Duration(minutes: 3);
  static const Duration suppressedCurrentKeepAliveFallback =
      Duration(minutes: 4);
}
