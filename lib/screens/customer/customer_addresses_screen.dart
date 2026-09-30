import 'package:flutter/material.dart';

import '../../services/address_service.dart';

class CustomerAddressesScreen extends StatefulWidget {
  const CustomerAddressesScreen({super.key});

  @override
  State<CustomerAddressesScreen> createState() =>
      _CustomerAddressesScreenState();
}

class _CustomerAddressesScreenState
    extends State<CustomerAddressesScreen> {
  final AddressService _addressService = AddressService();

  List<Map<String, dynamic>> _addresses = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loading = true;
    });

    try {
      final addresses =
          await _addressService.getAddresses();

      if (!mounted) return;

      setState(() {
        _addresses = addresses;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _addAddress() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddressFormScreen(),
      ),
    );

    if (changed == true) {
      await _loadAddresses();
    }
  }

  Future<void> _editAddress(
    Map<String, dynamic> address,
  ) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(
          address: address,
        ),
      ),
    );

    if (changed == true) {
      await _loadAddresses();
    }
  }

  Future<void> _deleteAddress(
    Map<String, dynamic> address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete address?'),
          content: const Text(
            'This address will be removed from your saved addresses.',
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

    if (confirmed != true) {
      return;
    }

    try {
      final response =
          await _addressService.deleteAddress(
        address['id'].toString(),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully'),
          ),
        );

        await _loadAddresses();
      } else {
        _showError(
          response['message']?.toString() ??
              'Unable to delete address',
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString());
    }
  }

  Future<void> _setDefault(
    Map<String, dynamic> address,
  ) async {
    try {
      final response =
          await _addressService.setDefaultAddress(
        address['id'].toString(),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Default address updated successfully',
            ),
          ),
        );

        await _loadAddresses();
      } else {
        _showError(
          response['message']?.toString() ??
              'Unable to update default address',
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _value(
    Map<String, dynamic> address,
    String key,
  ) {
    return address[key]?.toString() ?? '';
  }

  String _addressText(
    Map<String, dynamic> address,
  ) {
    final parts = <String>[];

    final line1 = _value(address, 'address_line1');
    final line2 = _value(address, 'address_line2');
    final city = _value(address, 'city');
    final state = _value(address, 'state');
    final postalCode = _value(address, 'postal_code');
    final landmark = _value(address, 'landmark');

    if (line1.isNotEmpty) parts.add(line1);
    if (line2.isNotEmpty) parts.add(line2);

    final cityState = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ].join(', ');

    if (cityState.isNotEmpty) {
      parts.add(cityState);
    }

    if (postalCode.isNotEmpty) {
      parts.add(postalCode);
    }

    if (landmark.isNotEmpty) {
      parts.add('Landmark: ');
    }

    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAddress,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAddresses,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _addresses.isEmpty
                ? ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 100),
                      Icon(
                        Icons.location_on_outlined,
                        size: 70,
                        color:
                            theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No saved addresses',
                        textAlign: TextAlign.center,
                        style: theme
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add an address for your laundry pickup and delivery.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _addAddress,
                        icon: const Icon(Icons.add),
                        label:
                            const Text('Add Address'),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      100,
                    ),
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      final address =
                          _addresses[index];

                      final label =
                          _value(address, 'label');

                      final isDefault =
                          address['is_default'] == true;

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 14,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons
                                        .location_on_outlined,
                                    color: theme
                                        .colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      label.isEmpty
                                          ? 'Saved Address'
                                          : label,
                                      style: theme
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                  if (isDefault)
                                    Chip(
                                      label:
                                          const Text(
                                        'Default',
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _addressText(address),
                                style: theme
                                    .textTheme
                                    .bodyMedium,
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _editAddress(
                                      address,
                                    ),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                    ),
                                    label:
                                        const Text(
                                      'Edit',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _deleteAddress(
                                      address,
                                    ),
                                    icon: const Icon(
                                      Icons
                                          .delete_outline,
                                    ),
                                    label:
                                        const Text(
                                      'Delete',
                                    ),
                                  ),
                                  if (!isDefault)
                                    TextButton.icon(
                                      onPressed: () =>
                                          _setDefault(
                                        address,
                                      ),
                                      icon: const Icon(
                                        Icons
                                            .check_circle_outline,
                                      ),
                                      label:
                                          const Text(
                                        'Set Default',
                                      ),
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
    );
  }
}

class AddressFormScreen extends StatefulWidget {
  final Map<String, dynamic>? address;

  const AddressFormScreen({
    super.key,
    this.address,
  });

  @override
  State<AddressFormScreen> createState() =>
      _AddressFormScreenState();
}

class _AddressFormScreenState
    extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AddressService _addressService =
      AddressService();

  late final TextEditingController _labelController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalController;
  late final TextEditingController _landmarkController;

  bool _isDefault = false;
  bool _saving = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();

    final address = widget.address;

    _labelController = TextEditingController(
      text: address?['label']?.toString() ?? '',
    );
    _line1Controller = TextEditingController(
      text:
          address?['address_line1']?.toString() ?? '',
    );
    _line2Controller = TextEditingController(
      text:
          address?['address_line2']?.toString() ?? '',
    );
    _cityController = TextEditingController(
      text: address?['city']?.toString() ?? '',
    );
    _stateController = TextEditingController(
      text: address?['state']?.toString() ?? '',
    );
    _postalController = TextEditingController(
      text:
          address?['postal_code']?.toString() ?? '',
    );
    _landmarkController = TextEditingController(
      text:
          address?['landmark']?.toString() ?? '',
    );

    _isDefault =
        address?['is_default'] == true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  String? _required(
    String? value,
    String field,
  ) {
    if (value == null || value.trim().isEmpty) {
      return ' is required';
    }

    return null;
  }

  String? _validatePostal(String? value) {
    final postal = value?.trim() ?? '';

    if (postal.isEmpty) {
      return 'Postal code is required';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(postal)) {
      return 'Enter a valid 6-digit postal code';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      Map<String, dynamic> response;

      if (_isEditing) {
        response =
            await _addressService.updateAddress(
          id: widget.address!['id'].toString(),
          label: _labelController.text,
          addressLine1:
              _line1Controller.text,
          addressLine2:
              _line2Controller.text,
          city: _cityController.text,
          state: _stateController.text,
          postalCode:
              _postalController.text,
          landmark:
              _landmarkController.text,
          isDefault: _isDefault,
        );
      } else {
        response =
            await _addressService.createAddress(
          label: _labelController.text,
          addressLine1:
              _line1Controller.text,
          addressLine2:
              _line2Controller.text,
          city: _cityController.text,
          state: _stateController.text,
          postalCode:
              _postalController.text,
          landmark:
              _landmarkController.text,
          isDefault: _isDefault,
        );
      }

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Address updated successfully'
                  : 'Address added successfully',
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        _showError(
          response['message']?.toString() ??
              'Unable to save address',
        );
      }
    } catch (error) {
      if (!mounted) return;

      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit Address'
              : 'Add Address',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Address Label',
                hintText: 'Home, Work, etc.',
                prefixIcon:
                    Icon(Icons.bookmark_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _line1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1',
                prefixIcon:
                    Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  _required(value, 'Address'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _line2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2',
                prefixIcon:
                    Icon(Icons.home_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon:
                    Icon(Icons.location_city_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  _required(value, 'City'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State',
                prefixIcon:
                    Icon(Icons.map_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  _required(value, 'State'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postalController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Postal Code',
                prefixIcon:
                    Icon(Icons.pin_drop_outlined),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: _validatePostal,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'Landmark',
                prefixIcon:
                    Icon(Icons.flag_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Set as default address',
              ),
              subtitle: const Text(
                'Use this address by default for orders',
              ),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed:
                    _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'Save Changes'
                            : 'Add Address',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
