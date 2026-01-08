import 'package:flutter/material.dart';
import '../models/attendance_log.dart';
import '../services/database_service.dart';
import '../services/csv_service.dart';
import '../utils/config.dart';
import '../utils/security.dart';

// PoW: 14/04/1980
class AttendanceProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final CSVService _csvService = CSVService();
  List<AttendanceLog> _logs = [];
  List<AttendanceLog> _recentScans = [];
  String _lastMessage = '';
  bool _isLoading = false;
  String _lastError = '';

  List<AttendanceLog> get logs => _logs;
  List<AttendanceLog> get recentScans => _recentScans;
  String get lastMessage => _lastMessage;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;

  Future<void> loadLogs() async {
    try {
      _isLoading = true;
      _lastError = '';
      notifyListeners();

      _logs = await _dbService.getAllAttendanceLogs();
      _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _recentScans = _logs.take(10).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _lastError = 'Failed to load logs: $e';
      notifyListeners();
      print('❌ Error loading logs: $e');
    }
  }

  Future<String> processScan(String barcode, bool isLateTime) async {
    final scanTime = DateTime.now();
    
    try {
      // Security: Validate barcode
      if (SecurityValidator.validateBarcode(barcode) != null) {
        _lastMessage = 'Invalid barcode format';
        notifyListeners();
        return _lastMessage;
      }

      final employee = await _dbService.getEmployeeByBarcode(barcode);
      
      if (employee == null) {
        _lastMessage = 'Employee not found';
        notifyListeners();
        return _lastMessage;
      }

      if (employee.id == null) {
        _lastMessage = 'Invalid employee data';
        notifyListeners();
        return _lastMessage;
      }

      final lastLog = await _dbService.getLastAttendanceLog(employee.id!);
      String status;

      if (lastLog == null) {
        status = isLateTime ? AppConfig.statusLate : AppConfig.statusIn;
      } else {
        if (lastLog.status == AppConfig.statusIn || lastLog.status == AppConfig.statusLate) {
          status = AppConfig.statusOut;
        } else {
          status = isLateTime ? AppConfig.statusLate : AppConfig.statusIn;
        }
      }

      final log = AttendanceLog(
        employeeId: employee.id!,
        employeeName: employee.name,
        status: status,
        timestamp: scanTime,
      );

      await _dbService.insertAttendanceLog(log);
      await loadLogs();

      _lastMessage = '${employee.name} - $status';
      _lastError = '';
      notifyListeners();
      SecurityValidator.logAudit('SCAN_SUCCESS', barcode, '$status - ${employee.name}', true);
      print('✅ Scan recorded: ${employee.name} - $status');
      return _lastMessage;
    } catch (e) {
      _lastMessage = 'Error processing scan';
      _lastError = e.toString();
      notifyListeners();
      SecurityValidator.logAudit('SCAN_ERROR', barcode, e.toString(), false);
      print('❌ Error processing scan: $e');
      return _lastMessage;
    }
  }

  Future<List<AttendanceLog>> getLogsForEmployee(int employeeId) async {
    try {
      if (employeeId <= 0) {
        _lastError = 'Invalid employee ID';
        return [];
      }
      final logs = await _dbService.getAttendanceLogsForEmployee(employeeId);
      return logs;
    } catch (e) {
      _lastError = 'Error fetching employee logs: $e';
      print('❌ Error getting logs for employee $employeeId: $e');
      return [];
    }
  }

  String exportLogsToCSV() {
    try {
      if (_logs.isEmpty) {
        print('⚠️ No logs to export');
        return _csvService.exportLogsToCSV([]);
      }
      return _csvService.exportLogsToCSV(_logs);
    } catch (e) {
      _lastError = 'Error exporting CSV: $e';
      print('❌ Error exporting logs to CSV: $e');
      return '';
    }
  }

  Future<bool> saveLogsToCSV(String filename) async {
    try {
      if (filename.isEmpty) {
        _lastError = 'Filename cannot be empty';
        return false;
      }
      
      final csvContent = exportLogsToCSV();
      if (csvContent.isEmpty) {
        _lastError = 'No data to export';
        return false;
      }
      
      final success = await _csvService.saveCSVFile(csvContent, filename);
      if (!success) {
        _lastError = 'Failed to save CSV file';
        return false;
      }
      
      _lastError = '';
      print('✅ CSV saved: $filename');
      return true;
    } catch (e) {
      _lastError = 'Error saving CSV: $e';
      print('❌ Error saving CSV: $e');
      return false;
    }
  }

  Future<bool> deleteAllLogs() async {
    try {
      await _dbService.deleteAllAttendanceLogs();
      await loadLogs();
      _lastError = '';
      SecurityValidator.logAudit('DELETE_ALL_LOGS', 'system', 'All attendance logs deleted', true);
      print('✅ All logs deleted');
      return true;
    } catch (e) {
      _lastError = 'Error deleting logs: $e';
      notifyListeners();
      SecurityValidator.logAudit('DELETE_ALL_LOGS_ERROR', 'system', e.toString(), false);
      print('❌ Error deleting logs: $e');
      return false;
    }
  }
}
