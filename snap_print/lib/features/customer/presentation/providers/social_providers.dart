import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';

/// Amazon-style ratings state, keyed by product.

final reviewSummaryProvider =
    FutureProvider.family<ReviewSummaryModel, String>((ref, productId) async {
  final ds = ref.read(customerDataSourceProvider);
  return ds.getReviewSummary(productId);
});

final productReviewsProvider =
    FutureProvider.family<List<ReviewModel>, ({String id, String sort})>((
  ref,
  key,
) async {
  final ds = ref.read(customerDataSourceProvider);
  return ds.getReviews(key.id, sort: key.sort);
});

final boughtTogetherProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, productId) async {
  final ds = ref.read(customerDataSourceProvider);
  return ds.getBoughtTogether(productId);
});

/// Server-backed wishlist ("List"), shared across devices.
class WishlistNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  WishlistNotifier(this._ds) : super(const AsyncLoading()) {
    refresh();
  }

  final CustomerRemoteDataSource _ds;

  Future<void> refresh() async {
    try {
      state = AsyncData(await _ds.getWishlistIds());
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  bool contains(String productId) =>
      state.maybeWhen(data: (ids) => ids.contains(productId), orElse: () => false);

  Future<void> toggle(String productId) async {
    final ds = _ds;
    final saved = contains(productId);
    final previous = state;
    // Optimistic update.
    state = state.whenData((ids) {
      final next = Set<String>.of(ids);
      if (saved) {
        next.remove(productId);
      } else {
        next.add(productId);
      }
      return next;
    });
    try {
      if (saved) {
        await ds.removeFromWishlist(productId);
      } else {
        await ds.addToWishlist(productId);
      }
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, AsyncValue<Set<String>>>(
  (ref) => WishlistNotifier(ref.read(customerDataSourceProvider)),
);

final wishlistProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  // Re-fetch the list whenever the id set changes.
  ref.watch(wishlistProvider);
  final ds = ref.read(customerDataSourceProvider);
  return ds.getWishlist();
});

final myReturnsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final ds = ref.read(customerDataSourceProvider);
  return ds.getMyReturns();
});
