import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/errors/presentation/views/status_error_page.dart';

void main() {
  testWidgets('client error page shows a matching 404 state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const ClientErrorPage(statusCode: 404, fallbackRoute: '/home'),
      ),
    );

    expect(find.text('404 - Page not found'), findsOneWidget);
    expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);

    final card = tester.widget<Card>(find.byType(Card));
    final icon = tester.widget<Icon>(find.byIcon(Icons.search_off_outlined));
    final expectedPrimary = Theme.of(
      tester.element(find.byType(ClientErrorPage)),
    ).colorScheme.primary;
    expect(card.elevation, 2);
    expect(icon.size, 56);
    expect(icon.color, expectedPrimary);
  });

  testWidgets('server error page shows a matching 503 state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const ServerErrorPage(statusCode: 503, fallbackRoute: '/home'),
      ),
    );

    expect(find.text('503 - Service unavailable'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });

  testWidgets('client error page does not overflow on a narrow short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const ClientErrorPage(statusCode: 401, fallbackRoute: '/home'),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('401 - Authentication required'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('server error page handles large text and a long message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2.5)),
          child: child!,
        ),
        home: const ServerErrorPage(
          statusCode: 500,
          message:
              'The server could not complete this request. Please wait a moment, '
              'check your connection, and try the operation again later.',
          fallbackRoute: '/home',
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('500 - Server error'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('root error page redirects to its fallback route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {'/home': (_) => const Scaffold(body: Text('Fallback home'))},
        home: const ClientErrorPage(statusCode: 404, fallbackRoute: '/home'),
      ),
    );

    await tester.tap(find.text('Go home'));
    await tester.pumpAndSettle();

    expect(find.text('Fallback home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
