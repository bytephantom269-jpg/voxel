import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';
import '../utils/security.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedPhotoPath;
  int? _editingEmployeeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployees();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Employee> _getFilteredEmployees(List<Employee> employees) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return employees;
    return employees.where((emp) => 
      emp.name.toLowerCase().contains(query) ||
      emp.barcode.toLowerCase().contains(query)
    ).toList();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Validate image file
        final validationError = SecurityValidator.validateImageFile(image.path);
        if (validationError != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(validationError), backgroundColor: Colors.red),
            );
          }
          return;
        }
        setState(() {
          _selectedPhotoPath = image.path;
        });
      }
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

  Future<void> _addOrUpdateEmployee() async {
    final barcode = _barcodeController.text.trim();
    final name = _nameController.text.trim();
    final position = _positionController.text.trim();

    // Validate inputs
    final barcodeError = SecurityValidator.validateBarcode(barcode);
    if (barcodeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(barcodeError), backgroundColor: Colors.red),
      );
      return;
    }

    final nameError = SecurityValidator.validateName(name);
    if (nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nameError), backgroundColor: Colors.red),
      );
      return;
    }

    if (position.isNotEmpty) {
      final positionError = SecurityValidator.validatePosition(position);
      if (positionError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(positionError), backgroundColor: Colors.red),
        );
        return;
      }
    }

    final employeeProvider = context.read<EmployeeProvider>();
    
    if (_editingEmployeeId == null) {
      final success = await employeeProvider.addEmployee(
        barcode,
        name,
        position: position.isEmpty ? null : position,
        photoPath: _selectedPhotoPath,
      );

      if (success) {
        _clearForm();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee added successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barcode already exists')),
          );
        }
      }
    } else {
      final employee = Employee(
        id: _editingEmployeeId,
        barcode: barcode,
        name: name,
        position: position.isEmpty ? null : position,
        photoPath: _selectedPhotoPath,
      );
      final success = await employeeProvider.updateEmployee(employee);
      
      if (success) {
        _clearForm();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee updated successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(employeeProvider.lastError.isNotEmpty 
                  ? employeeProvider.lastError 
                  : 'Failed to update employee'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _clearForm() {
    _barcodeController.clear();
    _nameController.clear();
    _positionController.clear();
    setState(() {
      _selectedPhotoPath = null;
      _editingEmployeeId = null;
    });
  }

  void _editEmployee(Employee employee) {
    _barcodeController.text = employee.barcode;
    _nameController.text = employee.name;
    _positionController.text = employee.position ?? '';
    setState(() {
      _selectedPhotoPath = employee.photoPath;
      _editingEmployeeId = employee.id;
    });
  }

  Future<void> _importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) {
        return; // User cancelled
      }

      if (!mounted) return;

      final filePath = result.files.single.path;
      if (filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get file path'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate file format
      if (!filePath.endsWith('.xlsx') && !filePath.endsWith('.xls')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid file format. Only .xlsx and .xls allowed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Validate file exists and size
      final file = File(filePath);
      if (!file.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final fileSize = file.lengthSync();
      if (fileSize > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File is too large (max 10MB)'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (fileSize == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File is empty'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Import the file
      final employeeProvider = context.read<EmployeeProvider>();
      final importResult = await employeeProvider.importEmployeesFromExcel(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importResult),
            duration: const Duration(seconds: 3),
            backgroundColor: importResult.contains('Error') ? Colors.red : Colors.green,
          ),
        );
      }
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

  Future<void> _deleteEmployee(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete $name?'),
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
      final employeeProvider = context.read<EmployeeProvider>();
      await employeeProvider.deleteEmployee(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final filteredEmployees = _getFilteredEmployees(employeeProvider.employees);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingEmployeeId == null ? 'Add New Employee' : 'Edit Employee',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        prefixIcon: const Icon(Icons.qr_code),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _positionController,
                      decoration: InputDecoration(
                        labelText: 'Position (Optional)',
                        prefixIcon: const Icon(Icons.work),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickPhoto,
                            icon: const Icon(Icons.image),
                            label: const Text('Add Photo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedPhotoPath != null)
                          CircleAvatar(
                            backgroundImage: FileImage(File(_selectedPhotoPath!)),
                            radius: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addOrUpdateEmployee,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_editingEmployeeId == null ? 'Add Employee' : 'Update Employee'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _importFromExcel,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import from Excel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Employee List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name or barcode',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (filteredEmployees.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No employees found'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredEmployees.length,
                itemBuilder: (context, index) {
                  final employee = filteredEmployees[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: employee.photoPath != null
                          ? CircleAvatar(
                              backgroundImage: FileImage(File(employee.photoPath!)),
                            )
                          : const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                      title: Text(employee.name),
                      subtitle: Text('${employee.position != null ? '${employee.position} • ' : ''}Barcode: ${employee.barcode}'),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editEmployee(employee),
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEmployee(employee.id!, employee.name),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
