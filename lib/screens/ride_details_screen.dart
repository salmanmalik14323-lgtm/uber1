import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/vehicle_tier.dart';
import '../state/ride_controller.dart';

class RideDetailsScreen extends StatelessWidget {
  const RideDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideController>();

    if (!ride.canBookRide) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride details')),
        body: const Center(
          child: Text('Pick pickup and destination on the map first.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ride details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Trip', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _AddressTile(
            icon: Icons.trip_origin,
            label: 'Pickup',
            address: ride.pickupAddress,
          ),
          const SizedBox(height: 8),
          _AddressTile(
            icon: Icons.flag,
            label: 'Destination',
            address: ride.destinationAddress,
          ),
          const SizedBox(height: 24),
          Text('Car type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...VehicleTier.values.map((tier) {
            final selected = ride.selectedVehicle == tier;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => context.read<RideController>().setVehicle(tier),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tier.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Fare multiplier ×${tier.fareMultiplier.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (ride.estimatedFare != null)
            Text(
              'Estimated fare: ₹${ride.estimatedFare!.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          const SizedBox(height: 16),
          Text('Passengers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Children under 5 ride free (no extra charge).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Adults / older children'),
              const Spacer(),
              IconButton(
                onPressed: ride.passengerCount <= 1
                    ? null
                    : () => context.read<RideController>().setPassengerCount(
                        ride.passengerCount - 1,
                      ),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '${ride.passengerCount}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: ride.passengerCount >= 6
                    ? null
                    : () => context.read<RideController>().setPassengerCount(
                        ride.passengerCount + 1,
                      ),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Children under 5'),
              const Spacer(),
              IconButton(
                onPressed: ride.childrenUnder5 <= 0
                    ? null
                    : () => context.read<RideController>().setChildrenUnder5(
                        ride.childrenUnder5 - 1,
                      ),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '${ride.childrenUnder5}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: ride.childrenUnder5 >= 5
                    ? null
                    : () => context.read<RideController>().setChildrenUnder5(
                        ride.childrenUnder5 + 1,
                      ),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.push('/ride/confirm'),
            child: const Text('Review & confirm'),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.icon,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(address),
      ),
    );
  }
}
