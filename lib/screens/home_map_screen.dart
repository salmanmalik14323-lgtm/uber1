import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/nominatim_geocode.dart';
import '../state/auth_controller.dart';
import '../state/ride_controller.dart';

/// Neutral world view when GPS is unavailable.
final LatLng _kFallback = LatLng(15, 0);
const double _kFallbackZoom = 2.5;

/// Shifts the map so the focused point sits lower (Uber-style).
const Offset _kMapContentOffset = Offset(0, -130);

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _pendingCameraTarget;
  double _pendingZoom = 14;
  final _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ride = context.read<RideController>();
      await _loadInitialLocation(ride);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  /// Geolocator handles web + mobile. Do not use [permission_handler] for
  /// location on web — it often never completes, leaving [pickup] null.
  Future<bool> _ensureGeolocatorPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Click the lock/info icon in the address bar and allow location, or use search.'
                  : 'Location permission denied. Use search or enable GPS in settings.',
            ),
          ),
        );
      }
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location is blocked for this site. Enable it in browser or app settings.',
            ),
          ),
        );
      }
      return false;
    }
    return true;
  }

  void _setFallbackPickup(RideController ride, {String? message}) {
    ride.setPickup(
      _kFallback,
      message ??
          'Allow location when prompted, or search “Where to?” and press →',
    );
    _moveTo(_kFallback, zoom: _kFallbackZoom);
  }

  Future<void> _applyPickupFromPosition(
    Position pos,
    RideController ride,
  ) async {
    final latLng = LatLng(pos.latitude, pos.longitude);
    // Set coordinates immediately so [canBookRide] works; refine address after.
    ride.setPickup(
      latLng,
      'Current location (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
    );
    await _moveTo(latLng, zoom: 14);

    try {
      final rev = await reverseLabel(pos.latitude, pos.longitude).timeout(
        const Duration(seconds: 10),
      );
      if (rev != null && rev.isNotEmpty && mounted) {
        ride.setPickup(latLng, rev);
      }
    } catch (_) {
      // Keep coordinate fallback label
    }
  }

  Future<void> _loadInitialLocation(RideController ride) async {
    // Web: permission_handler never finishing left pickup null → Continue stayed disabled.
    if (ride.pickup == null) {
      _setFallbackPickup(ride, message: 'Getting your location…');
    }

    final ok = await _ensureGeolocatorPermission();
    if (!ok) {
      _setFallbackPickup(ride);
      return;
    }

    if (!kIsWeb) {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Turn on device location services.')),
          );
        }
        _setFallbackPickup(ride);
        return;
      }
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      await _applyPickupFromPosition(pos, ride);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Could not read GPS ($e). Use search or allow location.'
                  : 'Could not get GPS: $e',
            ),
          ),
        );
      }
      _setFallbackPickup(ride);
    }
  }

  Future<void> _moveTo(LatLng target, {double zoom = 14}) async {
    _pendingCameraTarget = target;
    _pendingZoom = zoom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _flushPendingCamera();
    });
  }

  void _flushPendingCamera() {
    final t = _pendingCameraTarget;
    if (t == null) return;
    _pendingCameraTarget = null;
    _mapController.move(t, _pendingZoom, offset: _kMapContentOffset);
  }

  Future<void> _onDestinationSearch(RideController ride) async {
    final query = _destinationController.text;
    if (query.trim().isEmpty) return;
    try {
      final hit = await searchPlace(query);
      if (hit == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No place found. Try a fuller name (e.g. city + country).',
              ),
            ),
          );
        }
        return;
      }
      final latLng = hit.latLng;
      ride.setDestination(latLng, hit.formattedAddress);

      if (ride.pickup == null) {
        _setFallbackPickup(ride);
      }

      final pickup = ride.pickup;
      if (pickup != null) {
        var south = pickup.latitude < latLng.latitude
            ? pickup.latitude
            : latLng.latitude;
        var north = pickup.latitude > latLng.latitude
            ? pickup.latitude
            : latLng.latitude;
        var west = pickup.longitude < latLng.longitude
            ? pickup.longitude
            : latLng.longitude;
        var east = pickup.longitude > latLng.longitude
            ? pickup.longitude
            : latLng.longitude;
        const pad = 0.015;
        if ((north - south).abs() < 0.003) {
          south -= pad;
          north += pad;
        }
        if ((east - west).abs() < 0.003) {
          west -= pad;
          east += pad;
        }
        final bounds = LatLngBounds(LatLng(south, west), LatLng(north, east));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.only(
                top: 140,
                left: 48,
                right: 48,
                bottom: 200,
              ),
            ),
          );
        });
      } else {
        await _moveTo(latLng, zoom: 15);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  Future<void> _recenterGps(RideController ride) async {
    final ok = await _ensureGeolocatorPermission();
    if (!ok) return;

    if (!kIsWeb) {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Turn on device location services.')),
          );
        }
        return;
      }
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      await _applyPickupFromPosition(pos, ride);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get GPS: $e')),
        );
      }
    }
  }

  bool _isWorldFallback(LatLng p) =>
      (p.latitude - _kFallback.latitude).abs() < 0.0001 &&
      (p.longitude - _kFallback.longitude).abs() < 0.0001;

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideController>();
    final auth = context.watch<AuthController>();

    final pickup = ride.pickup ?? _kFallback;
    final dest = ride.destination;

    final markers = <Marker>[
      if (!_isWorldFallback(pickup))
        Marker(
          point: pickup,
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(Icons.my_location, color: Colors.blue.shade700, size: 32),
        ),
      if (dest != null)
        Marker(
          point: dest,
          width: 40,
          height: 48,
          alignment: Alignment.bottomCenter,
          child: Icon(Icons.location_on, color: Colors.red.shade700, size: 44),
        ),
    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _kFallback,
                initialZoom: _kFallbackZoom,
                onMapReady: _flushPendingCamera,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.uberride.app.uber_ride',
                ),
                SimpleAttributionWidget(
                  source: const Text('OpenStreetMap contributors'),
                  onTap: () async {
                    final u = Uri.parse('https://openstreetmap.org/copyright');
                    if (await canLaunchUrl(u)) {
                      await launchUrl(u, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hi, ${auth.displayLabel ?? "rider"}',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sign out',
                        onPressed: () {
                          context.read<RideController>().resetAll();
                          context.read<AuthController>().signOut();
                          context.go('/login');
                        },
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      leading: const Icon(Icons.trip_origin, color: Colors.black87),
                      title: const Text('Pickup'),
                      subtitle: Text(
                        ride.pickupAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Where to?',
                        hintText:
                            'Search any city, landmark, or address worldwide',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => _onDestinationSearch(ride),
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _onDestinationSearch(ride),
                    ),
                  ),
                  if (ride.estimatedFare != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Est. fare: ₹${ride.estimatedFare!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 140,
            child: FloatingActionButton(
              heroTag: 'loc',
              onPressed: () => _recenterGps(ride),
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: FilledButton(
                onPressed: ride.canBookRide
                    ? () => context.push('/ride/details')
                    : null,
                child: const Text('Continue to ride details'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
