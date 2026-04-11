import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/vehicle_tier.dart';
import '../utils/fare_calculator.dart';

class RideController extends ChangeNotifier {
  LatLng? pickup;
  String pickupAddress = 'Getting location…';
  LatLng? destination;
  String destinationAddress = '';
  double? estimatedFare;
  VehicleTier selectedVehicle = VehicleTier.mini;
  int passengerCount = 1;

  /// Children under 5 — informational; fare policy: no extra charge for them.
  int childrenUnder5 = 0;

  bool get canBookRide => pickup != null && destination != null;

  void setPickup(LatLng point, String address) {
    pickup = point;
    pickupAddress = address;
    _recomputeFare();
    notifyListeners();
  }

  void setDestination(LatLng point, String address) {
    destination = point;
    destinationAddress = address;
    _recomputeFare();
    notifyListeners();
  }

  void setVehicle(VehicleTier tier) {
    selectedVehicle = tier;
    _recomputeFare();
    notifyListeners();
  }

  void setPassengerCount(int count) {
    passengerCount = count.clamp(1, 6);
    notifyListeners();
  }

  void setChildrenUnder5(int count) {
    childrenUnder5 = count.clamp(0, 5);
    notifyListeners();
  }

  void _recomputeFare() {
    final p = pickup;
    final d = destination;
    if (p == null || d == null) {
      estimatedFare = null;
      return;
    }
    estimatedFare = computeFare(
      pickup: p,
      destination: d,
      tier: selectedVehicle,
    );
  }

  void refreshFareFromCurrentRoute() {
    _recomputeFare();
    notifyListeners();
  }

  /// Clears trip after booking; keeps pickup so the map stays usable.
  void resetDraft() {
    destination = null;
    destinationAddress = '';
    estimatedFare = null;
    selectedVehicle = VehicleTier.mini;
    passengerCount = 1;
    childrenUnder5 = 0;
    notifyListeners();
  }

  /// Full reset (e.g. sign out).
  void resetAll() {
    pickup = null;
    pickupAddress = 'Getting location…';
    resetDraft();
  }
}
