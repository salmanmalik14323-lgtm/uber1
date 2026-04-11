import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/ride_controller.dart';

enum PaymentOption { card, upi, wallet, cash }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentOption _selected = PaymentOption.upi;

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pay ₹${ride.estimatedFare?.toStringAsFixed(2) ?? '—'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${ride.selectedVehicle.label} · ${ride.pickupAddress.split(',').first} → ${ride.destinationAddress.split(',').first}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._options.map((rec) {
              final (option, label, icon) = rec;
              final selected = _selected == option;
              return ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: () => setState(() => _selected = option),
              );
            }),
            const Spacer(),
            FilledButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Booking confirmed'),
                    content: Text(
                      'Paid with ${_label(_selected)}. This is a demo — no real charge.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.read<RideController>().resetDraft();
                          context.go('/home');
                        },
                        child: const Text('Back to map'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Pay now'),
            ),
          ],
        ),
      ),
    );
  }

  String _label(PaymentOption o) {
    switch (o) {
      case PaymentOption.card:
        return 'Card';
      case PaymentOption.upi:
        return 'UPI';
      case PaymentOption.wallet:
        return 'Wallet';
      case PaymentOption.cash:
        return 'Cash';
    }
  }
}

const _options = <(PaymentOption, String, IconData)>[
  (PaymentOption.card, 'Credit / Debit card', Icons.credit_card),
  (PaymentOption.upi, 'UPI', Icons.account_balance),
  (PaymentOption.wallet, 'Wallet', Icons.account_balance_wallet_outlined),
  (PaymentOption.cash, 'Cash', Icons.payments_outlined),
];
