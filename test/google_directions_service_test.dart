import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/models/stop.dart';
import 'package:guinea_roads/services/google_directions_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const compiledApiKey = String.fromEnvironment('GOOGLE_ROUTES_API_KEY');

  setUp(GoogleRoutesService.clearCache);

  final origin = Stop(
    id: 'origin',
    name: 'Origine',
    latitude: 9.6412,
    longitude: -13.5784,
    order: 0,
    axe: 'test',
  );
  final destination = Stop(
    id: 'destination',
    name: 'Destination',
    latitude: 9.6500,
    longitude: -13.5900,
    order: 1,
    axe: 'test',
  );

  test('utilise la clé fournie à la compilation', () async {
    final service = GoogleRoutesService(
      client: MockClient(
        (_) async => http.Response(
          '{"routes":[{"duration":"60s","distanceMeters":1000,'
          '"polyline":{"encodedPolyline":"??"}}]}',
          200,
        ),
      ),
    );

    final route = await service.getDrivingRoute(origin, destination);

    expect(route.distanceKm, 1);
  }, skip: compiledApiKey.isEmpty);

  test('refuse une requête sans clé API', () async {
    final service = GoogleRoutesService(
      client: MockClient((_) async => http.Response('{}', 200)),
      apiKey: '',
    );

    expect(
      () => service.getDrivingRoute(origin, destination),
      throwsA(
        isA<DirectionsException>().having(
          (error) => error.message,
          'message',
          contains('absente'),
        ),
      ),
    );
  });

  test('décode une réponse Google Routes valide', () async {
    late http.Request capturedRequest;
    final service = GoogleRoutesService(
      apiKey: 'test-key',
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '{"routes":[{"duration":"120s","distanceMeters":2500,'
          '"polyline":{"encodedPolyline":"??_ibE_ibE"}}]}',
          200,
        );
      }),
    );

    final route = await service.getDrivingRoute(origin, destination);

    expect(capturedRequest.url.host, 'routes.googleapis.com');
    expect(capturedRequest.headers['X-Goog-Api-Key'], 'test-key');
    expect(route.distanceKm, 2.5);
    expect(route.durationMinutes, 2);
    expect(route.points, isNotEmpty);
  });

  test('remonte le message d’erreur de Google Routes', () async {
    final service = GoogleRoutesService(
      apiKey: 'test-key',
      client: MockClient(
        (_) async => http.Response(
          '{"error":{"message":"API non activée"}}',
          403,
        ),
      ),
    );

    expect(
      () => service.getDrivingRoute(origin, destination),
      throwsA(
        isA<DirectionsException>().having(
          (error) => error.message,
          'message',
          contains('API non activée'),
        ),
      ),
    );
  });

  test('réutilise une route en cache entre plusieurs services', () async {
    var requestCount = 0;
    final client = MockClient((_) async {
      requestCount++;
      return _validResponse();
    });
    final firstService = GoogleRoutesService(
      apiKey: 'test-key',
      client: client,
    );
    final secondService = GoogleRoutesService(
      apiKey: 'test-key',
      client: client,
    );

    await firstService.getDrivingRoute(origin, destination);
    await secondService.getDrivingRoute(origin, destination);

    expect(requestCount, 1);
  });

  test('partage une requête identique déjà en cours', () async {
    var requestCount = 0;
    final service = GoogleRoutesService(
      apiKey: 'test-key',
      client: MockClient((_) async {
        requestCount++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return _validResponse();
      }),
    );

    await Future.wait([
      service.getDrivingRoute(origin, destination),
      service.getDrivingRoute(origin, destination),
    ]);

    expect(requestCount, 1);
  });

  test('ne met pas les erreurs en cache', () async {
    var requestCount = 0;
    final service = GoogleRoutesService(
      apiKey: 'test-key',
      client: MockClient((_) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('{"error":{"message":"temporaire"}}', 503);
        }
        return _validResponse();
      }),
    );

    await expectLater(
      service.getDrivingRoute(origin, destination),
      throwsA(isA<DirectionsException>()),
    );
    final route = await service.getDrivingRoute(origin, destination);

    expect(requestCount, 2);
    expect(route.distanceKm, 1);
  });

  test('désactive le cache lorsque sa durée est nulle', () async {
    var requestCount = 0;
    final service = GoogleRoutesService(
      apiKey: 'test-key',
      cacheDuration: Duration.zero,
      client: MockClient((_) async {
        requestCount++;
        return _validResponse();
      }),
    );

    await service.getDrivingRoute(origin, destination);
    await service.getDrivingRoute(origin, destination);

    expect(requestCount, 2);
  });

  test('rafraîchit une route après expiration du cache', () async {
    var requestCount = 0;
    final service = GoogleRoutesService(
      apiKey: 'test-key',
      cacheDuration: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        requestCount++;
        return _validResponse();
      }),
    );

    await service.getDrivingRoute(origin, destination);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await service.getDrivingRoute(origin, destination);

    expect(requestCount, 2);
  });
}

http.Response _validResponse() {
  return http.Response(
    '{"routes":[{"duration":"60s","distanceMeters":1000,'
    '"polyline":{"encodedPolyline":"??"}}]}',
    200,
  );
}
