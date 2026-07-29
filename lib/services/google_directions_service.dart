import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

import '../models/stop.dart';

class DirectionsRoute {
  const DirectionsRoute({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final List<PointLatLng> points;
  final double distanceKm;
  final double durationMinutes;
}

class GoogleRoutesService {
  GoogleRoutesService({
    http.Client? client,
    String apiKey = _environmentApiKey,
    Duration cacheDuration = const Duration(minutes: 30),
    int maxCacheEntries = 100,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey,
        _cacheDuration = cacheDuration,
        _maxCacheEntries = maxCacheEntries;

  static const String _environmentApiKey = String.fromEnvironment(
    'GOOGLE_ROUTES_API_KEY',
  );

  final http.Client _client;
  final String _apiKey;
  final Duration _cacheDuration;
  final int _maxCacheEntries;
  final PolylinePoints _polylinePoints = PolylinePoints();

  static final Map<String, _CachedRoute> _cache = {};
  static final Map<String, Future<DirectionsRoute>> _pendingRequests = {};

  static void clearCache() {
    _cache.clear();
    _pendingRequests.clear();
  }

  Future<DirectionsRoute> getDrivingRoute(Stop from, Stop to) async {
    if (_apiKey.isEmpty) {
      throw const DirectionsException(
        'clé GOOGLE_ROUTES_API_KEY absente',
      );
    }

    final key = _cacheKey(from, to);
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => !entry.expiresAt.isAfter(now));

    final cached = _cache[key];
    if (cached != null) return cached.route;

    final pending = _pendingRequests[key];
    if (pending != null) return pending;

    final request = _fetchDrivingRoute(from, to);
    _pendingRequests[key] = request;
    try {
      final route = await request;
      if (_cacheDuration > Duration.zero) {
        _cache[key] = _CachedRoute(
          route: route,
          expiresAt: DateTime.now().add(_cacheDuration),
        );
        while (_cache.length > _maxCacheEntries && _cache.isNotEmpty) {
          _cache.remove(_cache.keys.first);
        }
      }
      return route;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  Future<DirectionsRoute> _fetchDrivingRoute(Stop from, Stop to) async {
    final uri = Uri.https(
      'routes.googleapis.com',
      '/directions/v2:computeRoutes',
    );

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,'
            'routes.polyline.encodedPolyline',
      },
      body: jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': from.latitude,
              'longitude': from.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': to.latitude,
              'longitude': to.longitude,
            },
          },
        },
        'travelMode': 'DRIVE',
        'computeAlternativeRoutes': false,
        'languageCode': 'fr',
        'units': 'METRIC',
      }),
    );

    if (response.statusCode != 200) {
      throw DirectionsException(_readGoogleError(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = body['routes'] as List<dynamic>? ?? const [];

    if (routes.isEmpty) {
      throw const DirectionsException('Google Routes : aucun itinéraire');
    }

    final route = routes.first as Map<String, dynamic>;
    final polyline = route['polyline'] as Map<String, dynamic>?;
    final encodedPoints = polyline?['encodedPolyline'] as String?;
    final distanceMeters = (route['distanceMeters'] as num?)?.toInt();
    final duration = route['duration'] as String?;

    if (encodedPoints == null ||
        encodedPoints.isEmpty ||
        distanceMeters == null ||
        duration == null) {
      throw const DirectionsException('réponse Google Routes incomplète');
    }

    final durationSeconds =
        double.tryParse(duration.replaceFirst(RegExp(r's$'), ''));
    if (durationSeconds == null) {
      throw const DirectionsException('durée Google Routes invalide');
    }

    return DirectionsRoute(
      points: _polylinePoints.decodePolyline(encodedPoints),
      distanceKm: distanceMeters / 1000,
      durationMinutes: durationSeconds / 60,
    );
  }

  String _cacheKey(Stop from, Stop to) {
    String coordinate(double value) => value.toStringAsFixed(6);
    return '${coordinate(from.latitude)},${coordinate(from.longitude)}'
        '>${coordinate(to.latitude)},${coordinate(to.longitude)}';
  }

  String _readGoogleError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return 'Google Routes : ${response.statusCode} — $message';
      }
    } on FormatException {
      // La réponse non JSON sera décrite par son code HTTP ci-dessous.
    }
    return 'Google Routes : erreur HTTP ${response.statusCode}';
  }
}

class _CachedRoute {
  const _CachedRoute({
    required this.route,
    required this.expiresAt,
  });

  final DirectionsRoute route;
  final DateTime expiresAt;
}

class DirectionsException implements Exception {
  const DirectionsException(this.message);

  final String message;

  @override
  String toString() => message;
}
