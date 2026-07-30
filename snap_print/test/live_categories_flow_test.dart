import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/core/constants/product_images.dart';
import 'package:snap_print/core/network/api_client.dart';
import 'package:snap_print/features/customer/data/datasources/customer_remote_datasource.dart';
import 'package:snap_print/features/customer/data/repositories/customer_repository_impl.dart';

void main() {
  const runLiveCategoryTest = bool.fromEnvironment(
    'SNAPPRINT_RUN_LIVE_CATEGORY_TEST',
  );

  test(
    'live backend categories parse through the Flutter repository',
    () async {
      final dataSource = CustomerRemoteDataSource(ApiClient());
      final repository = CustomerRepositoryImpl(dataSource);
      final categories = await repository.getCategories();

      expect(categories, isNotEmpty);
      expect(
        categories.every((category) => category.id.trim().isNotEmpty),
        isTrue,
      );
      expect(
        categories.every((category) => category.name.trim().isNotEmpty),
        isTrue,
      );
      expect(
        categories.every((category) => category.isActive),
        isTrue,
        reason: 'GET /categories should only expose active categories.',
      );

      final client = HttpClient();
      addTearDown(client.close);

      for (final category in categories) {
        final imageUrl =
            category.imageUrl ??
            kCategoryBannerImages[normalizeCategoryId(category.name)] ??
            '';

        expect(imageUrl, isNotEmpty, reason: '${category.name} needs an image');

        final request = await client.getUrl(Uri.parse(imageUrl));
        final response = await request.close();
        await response.drain<void>();

        expect(
          response.statusCode,
          lessThan(400),
          reason: '${category.name} image failed: $imageUrl',
        );
        expect(
          response.headers.contentType?.primaryType,
          'image',
          reason: '${category.name} must resolve to an image content type.',
        );
      }
    },
    skip: runLiveCategoryTest
        ? false
        : 'Set SNAPPRINT_RUN_LIVE_CATEGORY_TEST=true to hit the live backend.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
