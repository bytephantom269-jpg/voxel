import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/database_service.dart';
import '../services/csv_service.dart';
import '../services/export_service.dart';

class EmployeeProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final CSVService _csvService = CSVService();
  final ExportService _exportService = ExportService();
  List<Employee> _employees = [];
  bool _isLoading = false;
  String _lastError = '';

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;

  Future<void> loadEmployees() async {
    try {
      _isLoading = true;
      _lastError = '';
      notifyListeners();
      
      _employees = await _dbService.getAllEmployees();
      _employees.sort((a, b) => a.name.compareTo(b.name));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _lastError = 'Failed to load employees: $e';
      notifyListeners();
      print('Error loading employees: $e');
    }
  }

  Future<bool> addEmployee(String barcode, String name, {String? position, String? photoPath}) async {
    try {
      if (barcode.isEmpty || name.isEmpty) {
        _lastError = 'Barcode and name are required';
        notifyListeners();
        return false;
      }

      final existingEmployee = await _dbService.getEmployeeByBarcode(barcode);
      if (existingEmployee != null) {
        _lastError = 'Employee with barcode $barcode already exists';
        notifyListeners();
        return false;
      }

      final employee = Employee(
        barcode: barcode,
        name: name,
        position: position,
        photoPath: photoPath,
      );
      
      await _dbService.insertEmployee(employee);
      await loadEmployees();
      _lastError = '';
      return true;
    } catch (e) {
      _lastError = 'Error adding employee: $e';
      notifyListeners();
      print('Error adding employee: $e');
      return false;
    }
  }

  Future<String> importEmployeesFromCSV(String csvContent) async {
    final result = await _csvService.importEmployeesFromCSV(csvContent);
    await loadEmployees();
    return result;
  }

  Future<String> importEmployeesFromExcel(String filePath) async {
    try {
      _isLoading = true;
      _lastError = '';
      notifyListeners();

      final employees = await _exportService.importEmployeesFromExcel(filePath);
      
      int imported = 0;
      int duplicates = 0;
      final errors = <String>[];

      for (var emp in employees) {
        try {
          final existing = await _dbService.getEmployeeByBarcode(emp.barcode);
          if (existing != null) {
            duplicates++;
            continue;
          }
          await _dbService.insertEmployee(emp);
          imported++;
        } catch (e) {
          errors.add('${emp.barcode}: $e');
        }
      }

      await loadEmployees();
      _isLoading = false;
      
      String result = 'Imported: $imported, Duplicates: $duplicates';
      if (errors.isNotEmpty) {
        result += ', Errors: ${errors.length}';
      }
      return result;
    } catch (e) {
      _isLoading = false;
      _lastError = 'Error importing Excel: $e';
      notifyListeners();
      return 'Error importing Excel: $e';
    }
  }

  Future<bool> deleteEmployee(int id) async {
    try {
      await _dbService.deleteEmployee(id);
      await loadEmployees();
      _lastError = '';
      return true;
    } catch (e) {
      _lastError = 'Error deleting employee: $e';
      notifyListeners();
      print('Error deleting employee: $e');
      return false;
    }
  }

  Future<bool> updateEmployee(Employee employee) async {
    try {
      if (employee.barcode.isEmpty || employee.name.isEmpty) {
        _lastError = 'Barcode and name are required';
        notifyListeners();
        return false;
      }

      await _dbService.updateEmployee(employee);
      await loadEmployees();
      _lastError = '';
      return true;
    } catch (e) {
      _lastError = 'Error updating employee: $e';
      notifyListeners();
      print('Error updating employee: $e');
      return false;
    }
  }
}
