import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'state/auth_controller.dart';
import 'state/ride_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UberRideApp());
}

class UberRideApp extends StatefulWidget {
  const UberRideApp({super.key});

  @override
  State<UberRideApp> createState() => _UberRideAppState();
}

class _UberRideAppState extends State<UberRideApp> {
  late final AuthController _auth = AuthController();
  late final RideController _ride = RideController();
  late final GoRouter _router = createAppRouter(_auth);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: _auth),
        ChangeNotifierProvider<RideController>.value(value: _ride),
      ],
      child: MaterialApp.router(
        title: 'Uber Ride',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C0C0C)),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
