import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class BusinessClothTypesScreen extends StatefulWidget {
  const BusinessClothTypesScreen({super.key});

  @override
  State<BusinessClothTypesScreen> createState() =>
      _BusinessClothTypesScreenState();
}

class _BusinessClothTypesScreenState
    extends State<BusinessClothTypesScreen> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _clothTypes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClothTypes();
  }

  Future<void> _loadClothTypes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _api.get(
        ApiConfig.businessClothTypes,
      );

      final data = response['clothTypes'];

      if (data is List) {
        _clothTypes = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _clothTypes = [];
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

  Future<void> _showClothTypeForm({
    Map<String, dynamic>? clothType,
  }) async {
    final nameController = TextEditingController(
      text: clothType?['name']?.toString() ?? '',
    );

    final priceController = TextEditingController(
      text: clothType?['price']?.toString() ?? '',
    );

    bool active = clothType?['active'] != false;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                clothType == null
                    ? 'Add Cloth Type'
                    : 'Edit Cloth Type',
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Cloth Type',
                        hintText: 'Example: Shirt',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter cloth type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cloth Price per piece',
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
                        'price': double.parse(
                          priceController.text.trim(),
                        ),
                        'active': active,
                      };

                      if (clothType == null) {
                        await _api.post(
                          ApiConfig.businessClothTypes,
                          body: body,
                        );
                      } else {
                        final id = clothType['id']?.toString();

                        if (id == null) {
                          throw Exception(
                            'Cloth type ID is missing.',
                          );
                        }

                        await _api.patch(
                          '${ApiConfig.businessClothTypes}/$id',
                          body: body,
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    clothType == null ? 'Add' : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    priceController.dispose();

    if (result == true) {
      _loadClothTypes();
    }
  }

  Future<void> _toggleClothType(
    Map<String, dynamic> clothType,
  ) async {
    final id = clothType['id']?.toString();

    if (id == null) return;

    final currentActive = clothType['active'] != false;

    try {
      await _api.patch(
        '${ApiConfig.businessClothTypes}/$id/status',
        body: {
          'active': !currentActive,
        },
      );

      await _loadClothTypes();
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

  String _price(dynamic value) {
    final number = double.tryParse(
      value?.toString() ?? '',
    );

    if (number == null) {
      return '0.00';
    }

    return number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloth Types & Prices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClothTypes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClothTypeForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Cloth Type'),
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
                'Unable to load cloth types',
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
                onPressed: _loadClothTypes,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_clothTypes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadClothTypes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.checkroom,
              size: 60,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No cloth types added yet',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClothTypes,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          90,
        ),
        itemCount: _clothTypes.length,
        itemBuilder: (context, index) {
          final clothType = _clothTypes[index];

          final name =
              clothType['name']?.toString() ??
                  'Unnamed Cloth Type';

          final price = _price(clothType['price']);

          final active =
              clothType['active'] != false;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: const CircleAvatar(
                child: Icon(Icons.checkroom),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
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
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showClothTypeForm(
                      clothType: clothType,
                    );
                  } else if (value == 'toggle') {
                    _toggleClothType(clothType);
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
                      active
                          ? 'Deactivate'
                          : 'Activate',
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
