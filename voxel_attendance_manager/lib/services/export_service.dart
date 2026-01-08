import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/attendance_log.dart';
import '../models/employee.dart';

// PoW: 14/04/1980
class ExportService {
  static final ExportService _instance = ExportService._internal();

  factory ExportService() {
    return _instance;
  }

  ExportService._internal();

  Future<String?> exportLogsToExcel(List<AttendanceLog> logs) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Attendance Logs',
        fileName: 'attendance_logs_${DateTime.now().toString().replaceAll(':', '-')}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return null;

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        TextCellValue('Employee Name'),
        TextCellValue('Status'),
        TextCellValue('Timestamp'),
      ]);

      for (var log in logs) {
        // Security: Null-safety check
        if (log.employeeName.isEmpty || log.status.isEmpty) continue;
        
        sheet.appendRow([
          TextCellValue(log.employeeName.trim()),
          TextCellValue(log.status.trim()),
          TextCellValue(log.timestamp.toString()),
        ]);
      }

      final encoded = excel.encode();
      if (encoded == null) {
        throw Exception('Failed to encode Excel file');
      }

      final file = File(result);
      await file.writeAsBytes(encoded);

      return result;
    } catch (e) {
      throw Exception('Error exporting to Excel: $e');
    }
  }

  Future<String?> exportEmployeesToExcel(List<Employee> employees) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Employees',
        fileName: 'employees_${DateTime.now().toString().replaceAll(':', '-')}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return null;

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        TextCellValue('Barcode'),
        TextCellValue('Name'),
        TextCellValue('Position'),
        TextCellValue('PhotoPath'),
      ]);

      for (var emp in employees) {
        // Security: Null-safety and validation
        if (emp.barcode.isEmpty || emp.name.isEmpty) continue;
        
        sheet.appendRow([
          TextCellValue(emp.barcode.trim()),
          TextCellValue(emp.name.trim()),
          TextCellValue((emp.position ?? '').trim()),
          TextCellValue((emp.photoPath ?? '').trim()),
        ]);
      }

      final encoded = excel.encode();
      if (encoded == null) {
        throw Exception('Failed to encode Excel file');
      }

      final file = File(result);
      await file.writeAsBytes(encoded);

      return result;
    } catch (e) {
      throw Exception('Error exporting to Excel: $e');
    }
  }

  Future<List<Employee>> importEmployeesFromExcel(String filePath) async {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      
      if (excel.tables.isEmpty) {
        throw Exception('Excel file has no sheets');
      }
      
      final sheet = excel.tables.keys.first;
      final sheetData = excel.tables[sheet];
      if (sheetData == null) {
        throw Exception('Cannot read Excel sheet data');
      }
      
      final rows = sheetData.rows;
      if (rows.length <= 1) {
        throw Exception('Excel sheet is empty or contains only headers');
      }

      List<Employee> employees = [];

      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          if (row.isEmpty) continue;

          // Safely extract cell values
          String barcode = '';
          String name = '';
          String? position;
          String? photoPath;

          if (row.isNotEmpty && row[0] != null && row[0]?.value != null) {
            barcode = row[0]!.value.toString().trim();
          }

          if (row.length > 1 && row[1] != null && row[1]?.value != null) {
            name = row[1]!.value.toString().trim();
          }

          if (row.length > 2 && row[2] != null && row[2]?.value != null) {
            final posStr = row[2]!.value.toString().trim();
            if (posStr.isNotEmpty) {
              position = posStr;
            }
          }

          if (row.length > 3 && row[3] != null && row[3]?.value != null) {
            final photoStr = row[3]!.value.toString().trim();
            if (photoStr.isNotEmpty) {
              photoPath = photoStr;
            }
          }

          // Only add valid entries
          if (barcode.isNotEmpty && name.isNotEmpty) {
            employees.add(Employee(
              barcode: barcode,
              name: name,
              position: position,
              photoPath: photoPath,
            ));
          }
        } catch (e) {
          // Skip rows with parsing errors
          continue;
        }
      }

      if (employees.isNotEmpty) {
        return employees;
      } else {
        throw Exception('No valid employees found in Excel file');
      }
    } catch (e) {
      throw Exception('Error importing Excel: $e');
    }
  }
}
