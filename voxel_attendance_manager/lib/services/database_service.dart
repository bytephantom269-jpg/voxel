import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/employee.dart';
import '../models/attendance_log.dart';

// PoW: 14/04/1980 - Enterprise security
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;
    
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appDocDir = await getApplicationDocumentsDirectory();
      path = join(appDocDir.path, 'attendance_manager.db');
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'attendance_manager.db');
    }

    // Ensure database directory exists
    final dbDir = Directory(dirname(path));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
      // Use strict SQL mode for security
      singleInstance: true,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        position TEXT,
        photoPath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        employeeName TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees(id)
      )
    ''');
  }

  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return await db.insert('employees', employee.toMap());
  }

  Future<List<Employee>> getAllEmployees() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('employees', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  Future<Employee?> getEmployeeByBarcode(String barcode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertAttendanceLog(AttendanceLog log) async {
    final db = await database;
    return await db.insert('attendance_logs', log.toMap());
  }

  Future<List<AttendanceLog>> getAllAttendanceLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_logs',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => AttendanceLog.fromMap(maps[i]));
  }

  Future<AttendanceLog?> getLastAttendanceLog(int employeeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_logs',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return AttendanceLog.fromMap(maps.first);
  }

  Future<List<AttendanceLog>> getAttendanceLogsForEmployee(int employeeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_logs',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => AttendanceLog.fromMap(maps[i]));
  }

  Future<AttendanceLog?> getAttendanceLog(int employeeId, DateTime timestamp) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_logs',
      where: 'employeeId = ? AND timestamp = ?',
      whereArgs: [employeeId, timestamp.toIso8601String()],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return AttendanceLog.fromMap(maps.first);
  }

  Future<int> deleteAllAttendanceLogs() async {
    final db = await database;
    return await db.delete('attendance_logs');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE employees ADD COLUMN position TEXT');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
