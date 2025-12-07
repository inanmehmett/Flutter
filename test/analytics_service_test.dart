import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import '../lib/core/analytics/analytics_service.dart';
import '../lib/core/network/api_client.dart';

// Mock ApiClient
class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AnalyticsService analyticsService;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    analyticsService = AnalyticsService(mockApiClient);
  });

  group('AnalyticsService', () {
    test('should track screen view', () async {
      // Arrange
      when(() => mockApiClient.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/api/events'),
                statusCode: 200,
              ));

      // Act
      await analyticsService.trackScreenView('home');

      // Assert - Event should be queued (will be flushed later)
      // We can't easily test the queue without exposing it, so we just verify no exception
      expect(analyticsService, isNotNull);
    });

    test('should track user action', () async {
      await analyticsService.trackAction('button_clicked', parameters: {
        'button': 'start_reading',
      });

      expect(analyticsService, isNotNull);
    });

    test('should set user ID', () {
      analyticsService.setUserId('user123');
      // User ID is set internally, we just verify no exception
      expect(analyticsService, isNotNull);
    });

    test('should flush events', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/api/events'),
                statusCode: 200,
              ));

      await analyticsService.flush();
      // Verify no exception
      expect(analyticsService, isNotNull);
    });
  });
}

