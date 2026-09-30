import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class BusinessServicesScreen extends StatefulWidget {
  const BusinessServicesScreen({super.key});

  @override
  State<BusinessServicesScreen> createState() =>
      _BusinessServicesScreenState();
}

class _BusinessServicesScreenState extends State<BusinessServicesScreen> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _api.get(ApiConfig.businessServices);
      final data = response['services'];

      if (data is List) {
        _services = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _services = [];
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

  Future<void> _showServiceForm({
    Map<String, dynamic>? service,
  }) async {
    final nameController = TextEditingController(
      text: service?['name']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: service?['description']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: service?['price']?.toString() ?? '',
    );

    bool active = service?['active'] != false;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                service == null ? 'Add Service' : 'Edit Service',
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
                          labelText: 'Service Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter service name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price per piece',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final price = double.tryParse(
                            value?.trim() ?? '',
                          );

                          if (price == null || price < 0) {
                            return 'Enter a valid price';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: active,
                        onChanged: (value) {
                          setDialogState(() {
                            active = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      final body = {
                        'name': nameController.text.trim(),
                        'description':
                            descriptionController.text.trim(),
                        'price': double.parse(
                          priceController.text.trim(),
                        ),
                        'unit': 'item',
                        'active': active,
                      };

                      if (service == null) {
                        await _api.post(
                          ApiConfig.businessServices,
                          body: body,
                        );
                      } else {
                        final id = service['id']?.toString();

                        if (id == null) {
                          throw Exception('Service ID is missing.');
                        }

                        await _api.patch(
                          '${ApiConfig.businessServices}/$id',
                          body: body,
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: Text(
                    service == null ? 'Add' : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();

    if (result == true) {
      _loadServices();
    }
  }

  Future<void> _toggleService(
    Map<String, dynamic> service,
  ) async {
    final id = service['id']?.toString();

    if (id == null) return;

    final currentActive = service['active'] != false;

    try {
      await _api.patch(
        '${ApiConfig.businessServices}/$id/status',
        body: {
          'active': !currentActive,
        },
      );

      _loadServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _price(dynamic value) {
    if (value == null) return '0.00';

    final number = double.tryParse(value.toString());

    if (number == null) return value.toString();

    return number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServices,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServiceForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
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
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Unable to load services',
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
                onPressed: _loadServices,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_services.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadServices,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(Icons.local_laundry_service, size: 60),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No services added yet',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];

          final name =
              service['name']?.toString() ?? 'Unnamed Service';

          final description =
              service['description']?.toString() ?? '';

          final price = _price(service['price']);

          final active = service['active'] != false;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                child: const Icon(Icons.local_laundry_service),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty) Text(description),
                    const SizedBox(height: 5),
                    Text(
                      '₹$price per piece',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      active ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showServiceForm(service: service);
                  } else if (value == 'toggle') {
                    _toggleService(service);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      active ? 'Deactivate' : 'Activate',
                    ),
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
