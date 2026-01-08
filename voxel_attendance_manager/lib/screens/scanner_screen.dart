import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/employee_provider.dart';
import '../utils/config.dart';
import '../utils/security.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final barcode = _barcodeController.text.trim();
    
    // Validate barcode
    final validationError = SecurityValidator.validateBarcode(barcode);
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationError), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final settingsProvider = context.read<SettingsProvider>();
      final attendanceProvider = context.read<AttendanceProvider>();

      await attendanceProvider.processScan(barcode, settingsProvider.isLateTime);
      _barcodeController.clear();
      _focusNode.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SecurityValidator.getSafeErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConfig.statusIn:
        return Colors.green;
      case AppConfig.statusOut:
        return Colors.blue;
      case AppConfig.statusLate:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final dateFormat = DateFormat('hh:mm a');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan Barcode',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (settingsProvider.isLateTime ? Colors.red : Colors.green).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: settingsProvider.isLateTime ? Colors.red : Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Late Time: ${settingsProvider.lateTimeDisplay}',
                      style: TextStyle(
                        fontSize: 15,
                        color: settingsProvider.isLateTime ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _barcodeController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Barcode or Employee ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (attendanceProvider.lastMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        attendanceProvider.lastMessage,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Recent Scans',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: attendanceProvider.recentScans.isEmpty
                ? const Center(child: Text('No recent scans'))
                : ListView.builder(
                    itemCount: attendanceProvider.recentScans.length,
                    itemBuilder: (context, index) {
                      final scan = attendanceProvider.recentScans[index];
                      final statusColor = _getStatusColor(scan.status);
                      final employees = context.watch<EmployeeProvider>().employees;
                      
                      Employee? employee;
                      for (final emp in employees) {
                        if (emp.name == scan.employeeName) {
                          employee = emp;
                          break;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              if (employee?.photoPath != null)
                                CircleAvatar(
                                  backgroundImage: FileImage(File(employee!.photoPath!)),
                                  radius: 24,
                                )
                              else
                                CircleAvatar(
                                  backgroundColor: statusColor,
                                  radius: 24,
                                  child: Text(
                                    scan.status[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scan.employeeName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (employee?.position != null)
                                      Text(
                                        employee!.position!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      scan.status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateFormat.format(scan.timestamp),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
