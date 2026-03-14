import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  final file = File('assets/Sem2_schedule.xlsx');
  if (!file.existsSync()) {
    print('File not found');
    return;
  }
  
  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  
  for (var entry in excel.tables.entries) {
    print('\n--- Sheet: ${entry.key} ---');
    final table = entry.value;
    for (int r = 0; r < 20 && r < table.rows.length; r++) {
      final row = table.rows[r];
      print('Row $r: ${row.map((e) => e?.value).toList()}');
    }
  }
}
