import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/attendance_log.dart';
import '../providers/attendance_provider.dart';
import '../utils/config.dart';
import '../services/export_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadLogs();
    });
  }

  List<AttendanceLog> _filterLogs(List<AttendanceLog> logs) {
    return logs.where((log) {
      bool dateMatch = true;
      if (_startDate != null && _endDate != null) {
        final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
        final startDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final endDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        dateMatch = logDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            logDate.isBefore(endDate.add(const Duration(days: 1)));
      }

      bool statusMatch = _selectedStatus == 'All' || log.status == _selectedStatus;

      return dateMatch && statusMatch;
    }).toList();
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

  Future<void> _exportToExcel() async {
    try {
      final attendanceProvider = context.read<AttendanceProvider>();
      final exportService = ExportService();

      final filePath = await exportService.exportLogsToExcel(attendanceProvider.logs);

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: $filePath'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Logs'),
        content: const Text('Are you sure you want to delete all attendance logs? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AttendanceProvider>().deleteAllLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All logs deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final filteredLogs = _filterLogs(attendanceProvider.logs);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Logs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export Excel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _deleteAllLogs,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) setState(() => _startDate = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _startDate == null ? 'From Date' : DateFormat('MMM dd').format(_startDate!),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) setState(() => _endDate = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _endDate == null ? 'To Date' : DateFormat('MMM dd').format(_endDate!),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedStatus,
                        items: ['All', AppConfig.statusIn, AppConfig.statusOut, AppConfig.statusLate]
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status, style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedStatus = value);
                        },
                      ),
                      const SizedBox(width: 8),
                      if (_startDate != null || _endDate != null || _selectedStatus != 'All')
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                              _selectedStatus = 'All';
                            });
                          },
                        ),
                    ],
                  ),
                  if (filteredLogs.length != attendanceProvider.logs.length)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Showing ${filteredLogs.length} of ${attendanceProvider.logs.length} logs',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(
                    child: Text('No attendance logs match the filters'),
                  )
                : ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final statusColor = _getStatusColor(log.status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor,
                            child: Text(
                              log.status[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(log.employeeName),
                          subtitle: Text(dateFormat.format(log.timestamp)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              log.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
