// Replaced by FirestoreService — no longer used.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => throw UnimplementedError('Use FirestoreService instead'),
);
