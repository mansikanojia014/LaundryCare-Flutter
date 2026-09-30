import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class BusinessEmployeesScreen extends StatefulWidget {
  const BusinessEmployeesScreen({super.key});

  @override
  State<BusinessEmployeesScreen> createState() =>
      _BusinessEmployeesScreenState();
}

class _BusinessEmployeesScreenState
    extends State<BusinessEmployeesScreen> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _api.get(
        ApiConfig.employees,
      );

      final data = response['employees'];

      if (data is List) {
        _employees = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _employees = [];
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _showEmployeeForm({
    Map<String, dynamic>? employee,
  }) async {
    final nameController = TextEditingController(
      text: employee?['full_name']?.toString() ??
          employee?['fullName']?.toString() ??
          '',
    );

    final emailController = TextEditingController(
      text: employee?['email']?.toString() ?? '',
    );

    final passwordController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool obscurePassword = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                employee == null
                    ? 'Add Employee'
                    : 'Edit Employee',
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Enter employee name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email =
                              value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Enter email';
                          }

                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return 'Enter a valid email';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: employee == null
                              ? 'Password'
                              : 'New Password (optional)',
                          border:
                              const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword =
                                    !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (employee == null &&
                              (value == null ||
                                  value.isEmpty)) {
                            return 'Enter password';
                          }

                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Minimum 6 characters';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!
                        .validate()) {
                      return;
                    }

                    try {
                      final body = {
                        'fullName':
                            nameController.text.trim(),
                        'email':
                            emailController.text.trim(),
                        if (passwordController.text
                            .trim()
                            .isNotEmpty)
                          'password':
                              passwordController.text
                                  .trim(),
                      };

                      if (employee == null) {
                        await _api.post(
                          ApiConfig.employees,
                          body: body,
                        );
                      } else {
                        final id =
                            employee['id']?.toString();

                        if (id == null) {
                          throw Exception(
                            'Employee ID is missing.',
                          );
                        }

                        await _api.patch(
                          '${ApiConfig.employees}/$id',
                          body: body,
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString(),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    employee == null ? 'Add' : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    if (result == true) {
      _loadEmployees();
    }
  }

  Future<void> _deleteEmployee(
    Map<String, dynamic> employee,
  ) async {
    final id = employee['id']?.toString();

    if (id == null) return;

    final name =
        employee['full_name']?.toString() ??
            employee['fullName']?.toString() ??
            employee['email']?.toString() ??
            'this employee';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Employee'),
          content: Text(
            'Delete $name? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _api.delete(
        '${ApiConfig.employees}/$id',
      );

      await _loadEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  String _employeeName(
    Map<String, dynamic> employee,
  ) {
    return employee['full_name']?.toString() ??
        employee['fullName']?.toString() ??
        employee['name']?.toString() ??
        'Unnamed Employee';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmployees,
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () => _showEmployeeForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load employees',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEmployees,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_employees.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadEmployees,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.people_outline,
              size: 60,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No employees added yet',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEmployees,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          90,
        ),
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final employee = _employees[index];

          final name = _employeeName(employee);

          final email =
              employee['email']?.toString() ?? '';

          return Card(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.all(14),
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding:
                    const EdgeInsets.only(top: 6),
                child: Text(email),
              ),
              trailing:
                  PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEmployeeForm(
                      employee: employee,
                    );
                  } else if (value == 'delete') {
                    _deleteEmployee(employee);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
