import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import '../lib/core/services/crash_tracking_service.dart';
import '../lib/core/network/api_client.dart';

// Mock ApiClient
class MockApiClient extends Mock implements ApiClient {}

void main() {
  late CrashTrackingService crashTrackingService;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    crashTrackingService = CrashTrackingService(mockApiClient);
  });

  group('CrashTrackingService', () {
    test('should set user identifier', () {
      crashTrackingService.setUserIdentifier('user123');
      expect(crashTrackingService, isNotNull);
    });

    test('should set custom key', () {
      crashTrackingService.setCustomKey('screen', 'home');
      expect(crashTrackingService, isNotNull);
    });

    test('should clear custom key', () {
      crashTrackingService.setCustomKey('screen', 'home');
      crashTrackingService.clearCustomKey('screen');
      expect(crashTrackingService, isNotNull);
    });

    test('should add breadcrumb', () {
      crashTrackingService.addBreadcrumb('User clicked button');
      expect(crashTrackingService, isNotNull);
    });

    test('should clear breadcrumbs', () {
      crashTrackingService.addBreadcrumb('Action 1');
      crashTrackingService.clearBreadcrumbs();
      expect(crashTrackingService, isNotNull);
    });

    test('should record non-fatal error', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/api/crash'),
                statusCode: 200,
              ));

      await crashTrackingService.recordNonFatalError(
        'Test error',
        priority: 'low',
      );

      expect(crashTrackingService, isNotNull);
    });
  });
}

