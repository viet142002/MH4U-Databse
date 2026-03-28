import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Single global database instance, opened from the bundled asset.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openAppDatabase());
  ref.onDispose(db.close);
  return db;
});
