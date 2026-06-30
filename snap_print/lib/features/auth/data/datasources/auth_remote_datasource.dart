// Replaced by FirestoreService — no longer used.
// Kept to avoid breaking other imports until a full cleanup pass.
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AuthRemoteDataSource {}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (_) => throw UnimplementedError('Use FirestoreService instead'),
);
