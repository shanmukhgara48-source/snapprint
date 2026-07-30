import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_print/core/router/app_router.dart';
import 'package:snap_print/features/customer/data/models/category_model.dart';
import 'package:snap_print/features/customer/domain/entities/category_entity.dart';
import 'package:snap_print/features/customer/presentation/providers/catalog_provider.dart';
import 'package:snap_print/features/customer/presentation/widgets/category_grid.dart';

void main() {
  test('category model parses the backend category contract', () {
    final category = CategoryModel.fromJson(const {
      'id': 'cat-1',
      'name': 'Photo Prints',
      'icon': 'image',
      'image_url': null,
      'sort_order': 1,
      'is_active': true,
    });

    expect(category.id, 'cat-1');
    expect(category.name, 'Photo Prints');
    expect(category.icon, 'image');
    expect(category.imageUrl, isNull);
    expect(category.sortOrder, 1);
    expect(category.isActive, isTrue);
  });

  testWidgets('category grid renders visible categories and navigates safely', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: SingleChildScrollView(child: CategoryGrid()),
          ),
        ),
        GoRoute(
          path: AppRoutes.productList,
          builder: (context, state) => Scaffold(
            body: Text('category:${state.pathParameters['category']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async {
            return const [
              CategoryEntity(
                id: 'cat-1',
                name: 'Photo Prints',
                icon: 'image',
                imageUrl: '',
              ),
              CategoryEntity(
                id: 'cat-2',
                name: 'Hidden',
                icon: 'gift',
                imageUrl: '',
                isActive: false,
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Photo Prints'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);

    await tester.tap(find.text('Photo Prints'));
    await tester.pumpAndSettle();

    expect(find.text('category:Photo Prints'), findsOneWidget);
  });

  testWidgets('category grid shows retryable error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async {
            throw Exception('offline');
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: CategoryGrid())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Categories unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
