import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../models/vehicle_tier.dart';

double _rad(double deg) => deg * pi / 180;

/// Great-circle distance in kilometers.
double distanceKm(LatLng a, LatLng b) {
  const earthRadius = 6371.0;
  final dLat = _rad(b.latitude - a.latitude);
  final dLon = _rad(b.longitude - a.longitude);
  final lat1 = _rad(a.latitude);
  final lat2 = _rad(b.latitude);
  final h =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  return 2 * earthRadius * asin(min(1.0, sqrt(h)));
}

/// Base fare + distance with tier multiplier and small random jitter (demo).
double computeFare({
  required LatLng pickup,
  required LatLng destination,
  required VehicleTier tier,
  Random? random,
}) {
  final km = distanceKm(pickup, destination);
  const base = 49.0;
  const perKm = 12.0;
  final rng = random ?? Random();
  final jitter = rng.nextInt(40);
  final raw = (base + km * perKm) * tier.fareMultiplier + jitter;
  return (raw * 100).roundToDouble() / 100;
}
