import 'dart:io';
import 'package:csv/csv.dart';
import '../models/employee.dart';
import '../models/attendance_log.dart';
import 'database_service.dart';
import '../utils/security.dart';

class CSVService {
  static final CSVService _instance = CSVService._internal();
  final DatabaseService _dbService = DatabaseService();

  factory CSVService() {
    return _instance;
  }

  CSVService._internal();

  Future<String> importEmployeesFromCSV(String csvContent) async {
    try {
      // Validate CSV size to prevent DOS
      if (csvContent.length > 10 * 1024 * 1024) {
        return 'CSV file is too large';
      }

      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
      
      if (rows.isEmpty) {
        return 'CSV file is empty';
      }

      // Limit number of rows to import (prevent DOS)
      if (rows.length > 10000) {
        return 'CSV has too many rows (max 10000)';
      }

      int imported = 0;
      int duplicates = 0;
      int skipped = 0;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        
        // Security: Null-safety check
        if (row.isEmpty || row.length < 2) continue;
        if (row[0] == null || row[1] == null) continue;

        final barcode = row[0].toString().trim();
        final name = row[1].toString().trim();
        final position = row.length > 2 && row[2] != null ? row[2].toString().trim() : null;

        // Validate barcode and name
        if (SecurityValidator.validateBarcode(barcode) != null ||
            SecurityValidator.validateName(name) != null) {
          skipped++;
          continue;
        }

        if (barcode.isEmpty || name.isEmpty) continue;

        final existing = await _dbService.getEmployeeByBarcode(barcode);
        if (existing != null) {
          duplicates++;
          continue;
        }

        final employee = Employee(
          barcode: barcode,
          name: name,
          position: position?.isEmpty ?? true ? null : position,
        );

        await _dbService.insertEmployee(employee);
        imported++;
      }

      if (skipped > 0) {
        return 'Imported: $imported, Duplicates: $duplicates, Invalid: $skipped';
      }
      return 'Imported: $imported, Duplicates skipped: $duplicates';
    } catch (e) {
      return SecurityValidator.getSafeErrorMessage(e);
    }
  }

  String exportLogsToCSV(List<AttendanceLog> logs) {
    List<List<String>> csvData = [
      ['Employee Name', 'Status', 'Timestamp'],
    ];

    for (var log in logs) {
      // Security: Null-safety and sanitization
      if (log.employeeName.isEmpty || log.status.isEmpty) continue;
      
      csvData.add([
        log.employeeName.trim(),
        log.status.trim(),
        log.timestamp.toString(),
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  Future<bool> saveCSVFile(String csvContent, String filename) async {
    try {
      final directory = Directory.systemTemp;
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvContent);
      return true;
    } catch (e) {
      return false;
    }
  }
}
