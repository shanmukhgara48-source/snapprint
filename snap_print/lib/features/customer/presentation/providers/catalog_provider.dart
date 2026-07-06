import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/offer_entity.dart';

final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repo = ref.read(customerRepositoryProvider);
  return repo.getCategories();
});

final bannersProvider = FutureProvider<List<BannerEntity>>((ref) async {
  final repo = ref.read(customerRepositoryProvider);
  return repo.getBanners();
});

final offersProvider = FutureProvider<List<OfferEntity>>((ref) async {
  final repo = ref.read(customerRepositoryProvider);
  return repo.getActiveOffers();
});
