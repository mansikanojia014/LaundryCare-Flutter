import 'package:flutter/material.dart';

import '../../services/service_service.dart';
import 'package:flutter_app/screens/customer/customer_order_details_screen.dart';

class CustomerServicesScreen extends StatefulWidget {
  const CustomerServicesScreen({super.key});

  @override
  State<CustomerServicesScreen> createState() =>
      _CustomerServicesScreenState();
}

class _CustomerServicesScreenState
    extends State<CustomerServicesScreen> {
  final ServiceService _serviceService = ServiceService();

  List<Map<String, dynamic>> _clothTypes = [];
  List<Map<String, dynamic>> _availableServices = [];
  final List<Map<String, dynamic>> _orderItems = [];

  String? _selectedClothTypeId;
  String? _selectedServiceId;

  int _quantity = 1;

  bool _loading = true;
  bool _loadingServices = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClothTypes();
  }

  Future<void> _loadClothTypes() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final clothTypes = await _serviceService.getClothTypes();

      if (!mounted) return;

      setState(() {
        _clothTypes = clothTypes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadServices(String clothTypeId) async {
    try {
      setState(() {
        _loadingServices = true;
        _availableServices = [];
        _selectedServiceId = null;
      });

      final services =
          await _serviceService.getServicesForClothType(clothTypeId);

      if (!mounted) return;

      setState(() {
        _availableServices = services;
        _loadingServices = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingServices = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  void _addItem() {
    if (_selectedClothTypeId == null) {
      _showMessage('Please select a cloth type.');
      return;
    }

    if (_selectedServiceId == null) {
      _showMessage('Please select a service.');
      return;
    }

    final clothType = _clothTypes.firstWhere(
      (item) => item['id'].toString() == _selectedClothTypeId,
    );

    final service = _availableServices.firstWhere(
      (item) => item['id'].toString() == _selectedServiceId,
    );

    final price = double.tryParse(
          service['price'].toString(),
        ) ??
        0;

    final itemTotal = price * _quantity;

    setState(() {
      _orderItems.add({
        'clothTypeId': clothType['id'],
        'clothTypeName': clothType['name'],
        'serviceId': service['id'],
        'serviceName': service['name'],
        'unitPrice': price,
        'quantity': _quantity,
        'total': itemTotal,
      });

      _selectedClothTypeId = null;
      _selectedServiceId = null;
      _availableServices = [];
      _quantity = 1;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  double get _grandTotal {
    return _orderItems.fold(
      0,
      (sum, item) =>
          sum + (double.tryParse(item['total'].toString()) ?? 0),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _continue() {
    if (_orderItems.isEmpty) {
      _showMessage('Please add at least one item.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerOrderDetailsScreen(
          orderItems: _orderItems,
          total: _grandTotal,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Order'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Add Clothes & Services',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedClothTypeId,
                      decoration: const InputDecoration(
                        labelText: 'Cloth Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _clothTypes.map((cloth) {
                        return DropdownMenuItem<String>(
                          value: cloth['id'].toString(),
                          child: Text(
                            '${cloth['name']} — ?${cloth['price']}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedClothTypeId = value;
                        });

                        _loadServices(value);
                      },
                    ),

                    const SizedBox(height: 16),

                    if (_loadingServices)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_selectedClothTypeId != null &&
                        _availableServices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'No services available for this cloth type.',
                        ),
                      )
                    else if (_availableServices.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedServiceId,
                        decoration: const InputDecoration(
                          labelText: 'Service',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableServices.map((service) {
                          return DropdownMenuItem<String>(
                            value: service['id'].toString(),
                            child: Text(
                              '${service['name']} — ?${service['price']}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedServiceId = value;
                          });
                        },
                      ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity > 1
                              ? () {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add to Order'),
                      ),
                    ),

                    const SizedBox(height: 28),

                    if (_orderItems.isNotEmpty) ...[
                      const Text(
                        'Your Order',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ..._orderItems.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final item = entry.value;

                          return Card(
                            child: ListTile(
                              title: Text(
                                '${item['clothTypeName']} — ${item['serviceName']}',
                              ),
                              subtitle: Text(
                                '${item['quantity']} piece(s) × '
                                '?${item['unitPrice']}',
                              ),
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '?${double.parse(item['total'].toString()).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _removeItem(index),
                                    child: const Text(
                                      'Remove',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '?${_grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _continue,
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}




