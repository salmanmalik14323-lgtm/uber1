import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/ride_controller.dart';
import '../utils/fare_calculator.dart';

class RideConfirmationScreen extends StatefulWidget {
  const RideConfirmationScreen({super.key});

  @override
  State<RideConfirmationScreen> createState() => _RideConfirmationScreenState();
}

class _RideConfirmationScreenState extends State<RideConfirmationScreen> {
  final MapController _mapController = MapController();
  var _didFit = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideController>();
    final p = ride.pickup;
    final d = ride.destination;

    if (p == null || d == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm ride')),
        body: const Center(child: Text('Missing trip data.')),
      );
    }

    var south = p.latitude < d.latitude ? p.latitude : d.latitude;
    var north = p.latitude > d.latitude ? p.latitude : d.latitude;
    var west = p.longitude < d.longitude ? p.longitude : d.longitude;
    var east = p.longitude > d.longitude ? p.longitude : d.longitude;
    const pad = 0.008;
    if ((north - south).abs() < 0.002) {
      south -= pad;
      north += pad;
    }
    if ((east - west).abs() < 0.002) {
      west -= pad;
      east += pad;
    }
    final bounds = LatLngBounds(LatLng(south, west), LatLng(north, east));

    if (!_didFit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
        );
        _didFit = true;
      });
    }

    final dist = distanceKm(p, d);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm ride')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(
                  (p.latitude + d.latitude) / 2,
                  (p.longitude + d.longitude) / 2,
                ),
                initialZoom: 12,
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
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [p, d],
                      strokeWidth: 4,
                      color: Colors.black87,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: p,
                      width: 36,
                      height: 40,
                      alignment: Alignment.bottomCenter,
                      child: const Icon(Icons.trip_origin, color: Colors.green, size: 36),
                    ),
                    Marker(
                      point: d,
                      width: 40,
                      height: 48,
                      alignment: Alignment.bottomCenter,
                      child: Icon(Icons.location_on, color: Colors.red.shade700, size: 44),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route preview', style: Theme.of(context).textTheme.titleSmall),
                Text(
                  'Straight-line distance ~ ${dist.toStringAsFixed(1)} km (not turn-by-turn)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Divider(height: 24),
                _SummaryRow('Pickup', ride.pickupAddress),
                const SizedBox(height: 8),
                _SummaryRow('Drop', ride.destinationAddress),
                const SizedBox(height: 8),
                _SummaryRow('Car', ride.selectedVehicle.label),
                const SizedBox(height: 8),
                _SummaryRow(
                  'Passengers',
                  '${ride.passengerCount} seated'
                      '${ride.childrenUnder5 > 0 ? ', ${ride.childrenUnder5} children under 5 (free)' : ''}',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  'Fare',
                  ride.estimatedFare != null
                      ? '₹${ride.estimatedFare!.toStringAsFixed(2)}'
                      : '—',
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton(
              onPressed: () => context.push('/payment'),
              child: const Text('Continue to payment'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
