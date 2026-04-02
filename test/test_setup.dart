import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes the FFI database factory for testing.
/// Call this in setUpAll() before any database tests.
void setupDatabaseForTesting() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
