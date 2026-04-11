import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Free geocoding via OpenStreetMap Nominatim (no API key).
/// Respect usage policy: identify app; avoid bulk requests.
/// https://operations.osmfoundation.org/policies/nominatim/
const String _userAgent =
    'UberRide/1.0 (com.uberride.app.uber_ride; flutter educational app)';

class GeocodeHit {
  GeocodeHit({required this.latLng, required this.formattedAddress});

  final LatLng latLng;
  final String formattedAddress;
}

Future<GeocodeHit?> searchPlace(String rawQuery) async {
  final query = rawQuery.trim();
  if (query.isEmpty) return null;

  final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': query,
    'format': 'json',
    'limit': '1',
  });

  try {
    final res = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final list = jsonDecode(res.body) as List<dynamic>;
    if (list.isEmpty) return null;
    final first = list.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    final name = first['display_name'] as String? ?? query;
    return GeocodeHit(latLng: LatLng(lat, lon), formattedAddress: name);
  } catch (_) {
    return null;
  }
}

/// Reverse geocode for pickup label (free).
Future<String?> reverseLabel(double lat, double lon) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
    'lat': lat.toString(),
    'lon': lon.toString(),
    'format': 'json',
  });
  try {
    final res = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['display_name'] as String?;
  } catch (_) {
    return null;
  }
}
