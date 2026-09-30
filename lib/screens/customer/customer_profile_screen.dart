import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState
    extends State<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerService = CustomerService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _customerCode;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _customerService.getProfile();

      if (!mounted) return;

      if (response['success'] != true) {
        setState(() {
          _error =
              response['message']?.toString() ??
              'Unable to load profile';
          _loading = false;
        });
        return;
      }

      final profile = response['user'] ??
          response['customer'] ??
          response['profile'];

      if (profile is Map) {
        _nameController.text =
            profile['full_name']?.toString() ??
            profile['fullName']?.toString() ??
            '';

        _phoneController.text =
            profile['phone']?.toString() ?? '';

        _customerCode =
            profile['customer_code']?.toString() ??
            profile['customerCode']?.toString();

        _email =
            profile['email']?.toString();
      }

      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final response =
          await _customerService.updateProfile(
        fullName: _nameController.text,
        phone: _phoneController.text,
      );

      if (!mounted) return;

      if (response['success'] != true) {
        setState(() {
          _error =
              response['message']?.toString() ??
              'Unable to update profile';
          _saving = false;
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );

      await _loadProfile();

      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _saving = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final response =
          await _customerService.deleteAccount();

      if (!mounted) return;

      if (response['success'] == true) {
        await context.read<AuthProvider>().logout();

        if (!mounted) return;

        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ??
                  'Unable to delete account',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          child: Text(
                            _nameController.text.isEmpty
                                ? '?'
                                : _nameController.text
                                    .trim()
                                    .substring(0, 1)
                                    .toUpperCase(),
                            style:
                                theme.textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_customerCode != null &&
                            _customerCode!.isNotEmpty)
                          Text(
                            'Customer Code: ',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (_email != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _email!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon:
                              Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Name is required';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType:
                            TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon:
                              Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed:
                              _saving ? null : _saveProfile,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed: _deleteAccount,
                  child: const Text('Delete Account'),
                ),
              ],
            ),
    );
  }
}
