import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/core/constants/product_images.dart';

void main() {
  test(
    'every live backend product resolves to a loadable image URL',
    () async {
      final apiUrl =
          Platform.environment['SNAPPRINT_AUDIT_API_URL'] ??
          'http://127.0.0.1:8001';
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);

      final products = await _fetchProducts(client, apiUrl);
      expect(products, isNotEmpty);

      final missing = <String>[];
      final urlsByProduct = <String, String>{};
      for (final product in products) {
        final url = resolveNetworkProductImage(
          productId: product['id'] as String,
          categoryId: product['category'] as String,
          productName: product['name'] as String,
          description: product['description'] as String?,
          imageUrl: _primaryImage(product),
        );
        if (url.trim().isEmpty) {
          missing.add(product['name'] as String);
        } else {
          urlsByProduct[product['name'] as String] = url;
        }
      }

      expect(missing, isEmpty, reason: 'Products missing image URLs: $missing');

      final broken = <String>[];
      for (final entry in urlsByProduct.entries) {
        final result = await _loadsImage(client, entry.value);
        if (result != null) broken.add('${entry.key}: $result');
      }

      expect(broken, isEmpty, reason: 'Broken product images: $broken');
      client.close(force: true);
    },
    skip: Platform.environment['SNAPPRINT_RUN_LIVE_IMAGE_TEST'] == 'true'
        ? false
        : 'Set SNAPPRINT_RUN_LIVE_IMAGE_TEST=true to hit the live backend and image CDN.',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<List<Map<String, dynamic>>> _fetchProducts(
  HttpClient client,
  String apiUrl,
) async {
  final request = await client.getUrl(Uri.parse('$apiUrl/products?limit=100'));
  final response = await request.close().timeout(const Duration(seconds: 20));
  expect(response.statusCode, 200);

  final body = await utf8.decodeStream(response);
  final decoded = jsonDecode(body) as Map<String, dynamic>;
  final items = (decoded['items'] as List).cast<Map<String, dynamic>>();
  final total = decoded['total'] as int;

  if (items.length >= total) return items;

  final all = [...items];
  var page = 2;
  while (all.length < total) {
    final pageRequest = await client.getUrl(
      Uri.parse('$apiUrl/products?limit=100&page=$page'),
    );
    final pageResponse = await pageRequest.close().timeout(
      const Duration(seconds: 20),
    );
    expect(pageResponse.statusCode, 200);
    final pageBody = await utf8.decodeStream(pageResponse);
    final pageDecoded = jsonDecode(pageBody) as Map<String, dynamic>;
    all.addAll((pageDecoded['items'] as List).cast<Map<String, dynamic>>());
    page++;
  }

  return all;
}

String _primaryImage(Map<String, dynamic> product) {
  final images = product['images'];
  if (images is List && images.isNotEmpty && images.first is String) {
    return images.first as String;
  }
  return '';
}

Future<String?> _loadsImage(HttpClient client, String url) async {
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(
      HttpHeaders.acceptHeader,
      'image/avif,image/webp,image/*,*/*',
    );
    final response = await request.close().timeout(const Duration(seconds: 20));
    final contentType = response.headers.contentType?.mimeType ?? '';
    await response.drain<void>();
    if (response.statusCode >= 400) return 'HTTP ${response.statusCode}';
    if (!contentType.startsWith('image/')) return 'content-type=$contentType';
    return null;
  } catch (error) {
    return error.toString();
  }
}
