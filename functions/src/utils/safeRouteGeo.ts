import {
  LiveLocationRecord,
  RoutePointRecord,
} from "../types";

const EARTH_RADIUS_METERS = 6371000;

function toRadians(value: number) {
  return (value * Math.PI) / 180;
}

function projectMeters(
  latitude: number,
  longitude: number,
  originLatitude: number,
  originLongitude: number
) {
  const latRad = toRadians(latitude);
  const lonRad = toRadians(longitude);
  const originLatRad = toRadians(originLatitude);
  const originLonRad = toRadians(originLongitude);
  const x =
    (lonRad - originLonRad) * Math.cos((latRad + originLatRad) / 2) *
    EARTH_RADIUS_METERS;
  const y = (latRad - originLatRad) * EARTH_RADIUS_METERS;
  return {x, y};
}

export function haversineMeters(
  aLatitude: number,
  aLongitude: number,
  bLatitude: number,
  bLongitude: number
) {
  const dLat = toRadians(bLatitude - aLatitude);
  const dLng = toRadians(bLongitude - aLongitude);
  const lat1 = toRadians(aLatitude);
  const lat2 = toRadians(bLatitude);

  const sinLat = Math.sin(dLat / 2);
  const sinLng = Math.sin(dLng / 2);
  const a =
    sinLat * sinLat +
    Math.cos(lat1) * Math.cos(lat2) * sinLng * sinLng;
  return 2 * EARTH_RADIUS_METERS * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function pointInCircleMeters(
  latitude: number,
  longitude: number,
  centerLatitude: number,
  centerLongitude: number,
  radiusMeters: number
) {
  return (
    haversineMeters(latitude, longitude, centerLatitude, centerLongitude) <=
    radiusMeters
  );
}

export function distancePointToSegmentMeters(
  latitude: number,
  longitude: number,
  segmentStart: RoutePointRecord,
  segmentEnd: RoutePointRecord
) {
  const originLatitude = latitude;
  const originLongitude = longitude;
  const point = {x: 0, y: 0};
  const start = projectMeters(
    segmentStart.latitude,
    segmentStart.longitude,
    originLatitude,
    originLongitude
  );
  const end = projectMeters(
    segmentEnd.latitude,
    segmentEnd.longitude,
    originLatitude,
    originLongitude
  );

  const dx = end.x - start.x;
  const dy = end.y - start.y;
  const lengthSquared = dx * dx + dy * dy;

  if (lengthSquared <= 0.0001) {
    return Math.hypot(start.x - point.x, start.y - point.y);
  }

  const t = Math.max(
    0,
    Math.min(
      1,
      ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
    )
  );
  const projectedX = start.x + t * dx;
  const projectedY = start.y + t * dy;

  return Math.hypot(projectedX - point.x, projectedY - point.y);
}

export function distancePointToPolylineMeters(
  latitude: number,
  longitude: number,
  points: RoutePointRecord[]
) {
  if (!points.length) return Number.POSITIVE_INFINITY;
  if (points.length === 1) {
    return haversineMeters(
      latitude,
      longitude,
      points[0].latitude,
      points[0].longitude
    );
  }

  let minDistance = Number.POSITIVE_INFINITY;
  for (let index = 1; index < points.length; index += 1) {
    const distance = distancePointToSegmentMeters(
      latitude,
      longitude,
      points[index - 1],
      points[index]
    );
    if (distance < minDistance) {
      minDistance = distance;
    }
  }
  return minDistance;
}

export function distanceLocationToRouteMeters(
  location: LiveLocationRecord,
  points: RoutePointRecord[]
) {
  return distancePointToPolylineMeters(
    location.latitude,
    location.longitude,
    points
  );
}

