import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';

class FirestoreProductDataSource {
  FirestoreProductDataSource(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  Future<List<ProductModel>> getProducts({
    String? categoryId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _products.where('isActive', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }

    q = q.orderBy('sortOrder').limit(limit);

    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.get();
    return snap.docs.map(ProductModel.fromFirestore).toList();
  }

  Future<ProductModel> getProductById(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) throw Exception('Product $id not found');
    return ProductModel.fromFirestore(doc);
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    // Firestore doesn't support full-text; search by name prefix client-side
    final snap = await _products.where('isActive', isEqualTo: true).get();
    final lower = query.toLowerCase();
    return snap.docs
        .map(ProductModel.fromFirestore)
        .where((p) =>
            p.name.toLowerCase().contains(lower) ||
            p.categoryName.toLowerCase().contains(lower))
        .toList();
  }
}

final firestoreProductDataSourceProvider =
    Provider<FirestoreProductDataSource>((ref) {
  return FirestoreProductDataSource(FirebaseFirestore.instance);
});
