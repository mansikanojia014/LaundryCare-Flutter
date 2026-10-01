import 'package:flutter/material.dart';

import '../../services/address_service.dart';
import '../../services/order_service.dart';

class CustomerOrderDetailsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;
  final double total;

  const CustomerOrderDetailsScreen({
    super.key,
    required this.orderItems,
    required this.total,
  });

  @override
  State<CustomerOrderDetailsScreen> createState() =>
      _CustomerOrderDetailsScreenState();
}

class _CustomerOrderDetailsScreenState
    extends State<CustomerOrderDetailsScreen> {
  final AddressService _addressService = AddressService();
  final OrderService _orderService = OrderService();

  final TextEditingController _notesController =
      TextEditingController();
  final TextEditingController _upiController =
      TextEditingController();
  final TextEditingController _discountController =
      TextEditingController();

  List<Map<String, dynamic>> _addresses = [];

  String? _pickupAddressId;
  String? _dropoffAddressId;

  DateTime? _pickupDate;
  DateTime? _dropoffDate;

  TimeOfDay? _pickupTime;
  TimeOfDay? _dropoffTime;

  String _paymentMethod = 'cash';

  bool _loading = true;
  bool _placingOrder = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _upiController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await _addressService.getAddresses();

      if (!mounted) return;

      setState(() {
        _addresses = addresses;
        _loading = false;

        if (addresses.isNotEmpty) {
          final defaultAddress = addresses.firstWhere(
            (address) => address['isDefault'] == true,
            orElse: () => addresses.first,
          );

          final defaultId = defaultAddress['id']?.toString();

          _pickupAddressId = defaultId;
          _dropoffAddressId = defaultId;
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _selectPickupDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? today,
      firstDate: DateTime(
        today.year,
        today.month,
        today.day,
      ),
      lastDate: DateTime(
        today.year + 2,
        today.month,
        today.day,
      ),
    );

    if (selected == null) return;

    setState(() {
      _pickupDate = selected;

      if (_dropoffDate != null &&
          !_dropoffDate!.isAfter(selected)) {
        _dropoffDate =
            selected.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _selectDropoffDate() async {
    final minimumDate = _pickupDate == null
        ? DateTime.now().add(const Duration(days: 1))
        : _pickupDate!.add(const Duration(days: 1));

    final selected = await showDatePicker(
      context: context,
      initialDate: _dropoffDate ?? minimumDate,
      firstDate: minimumDate,
      lastDate: DateTime(
        minimumDate.year + 2,
        minimumDate.month,
        minimumDate.day,
      ),
    );

    if (selected == null) return;

    setState(() {
      _dropoffDate = selected;
    });
  }

  Future<void> _selectPickupTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime:
          _pickupTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (selected == null) return;

    setState(() {
      _pickupTime = selected;
    });
  }

  Future<void> _selectDropoffTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime:
          _dropoffTime ?? const TimeOfDay(hour: 18, minute: 0),
    );

    if (selected == null) return;

    setState(() {
      _dropoffTime = selected;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';

    return time.format(context);
  }

  String _apiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _apiTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _addressText(Map<String, dynamic> address) {
    final label = address['label']?.toString() ?? 'Address';

    final line = address['addressLine1']?.toString() ??
        address['address_line']?.toString() ??
        '';

    final area = address['area']?.toString() ?? '';
    final city = address['city']?.toString() ?? '';
    final pincode = address['postalCode']?.toString() ??
        address['pincode']?.toString() ??
        '';

    final parts = [
      line,
      area,
      city,
      pincode,
    ].where((value) => value.isNotEmpty).toList();

    return parts.isEmpty
        ? label
        : '$label — ${parts.join(', ')}';
  }

  bool _validate() {
    if (_pickupAddressId == null ||
        _dropoffAddressId == null) {
      _showMessage(
        'Please select pickup and drop-off addresses.',
      );
      return false;
    }

    if (_pickupDate == null ||
        _pickupTime == null ||
        _dropoffDate == null ||
        _dropoffTime == null) {
      _showMessage(
        'Please select all pickup and drop-off date and time details.',
      );
      return false;
    }

    final pickup = DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
      _pickupTime!.hour,
      _pickupTime!.minute,
    );

    final dropoff = DateTime(
      _dropoffDate!.year,
      _dropoffDate!.month,
      _dropoffDate!.day,
      _dropoffTime!.hour,
      _dropoffTime!.minute,
    );

    if (!dropoff.isAfter(pickup)) {
      _showMessage('Drop-off must be after pickup.');
      return false;
    }

    if (dropoff.difference(pickup) <
        const Duration(hours: 24)) {
      _showMessage(
        'Drop-off must be at least 24 hours after pickup.',
      );
      return false;
    }

    if (_paymentMethod == 'upi' &&
        _upiController.text.trim().isEmpty) {
      _showMessage(
        'Please enter the UPI transaction ID.',
      );
      return false;
    }

    return true;
  }

  Future<void> _placeOrder() async {
    if (_placingOrder || !_validate()) return;

    setState(() {
      _placingOrder = true;
    });

    try {
      final items = widget.orderItems.map((item) {
        return {
          'clothTypeId': item['clothTypeId'].toString(),
          'serviceId': item['serviceId'].toString(),
          'quantity': item['quantity'],
        };
      }).toList();

      final response = await _orderService.createOrder(
        pickupAddressId: _pickupAddressId!,
        deliveryAddressId: _dropoffAddressId!,
        pickupDate: _apiDate(_pickupDate!),
        pickupTime: _apiTime(_pickupTime!),
        dropoffDate: _apiDate(_dropoffDate!),
        dropoffTime: _apiTime(_dropoffTime!),
        items: items,
        paymentMethod: _paymentMethod,
        discountCode: _discountController.text.trim().isEmpty
            ? null
            : _discountController.text.trim(),
        upiTransactionId: _paymentMethod == 'upi'
            ? _upiController.text.trim()
            : null,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      final order = response['order'];

      final orderNumber = order is Map
          ? order['orderNumber']?.toString()
          : null;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Order Placed'),
            content: Text(
              orderNumber == null
                  ? 'Your laundry order has been placed successfully.'
                  : 'Your order $orderNumber has been placed successfully.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _placingOrder = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _addressDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: _addresses
          .map((address) {
            final id = address['id']?.toString();

            if (id == null) return null;

            return DropdownMenuItem<String>(
              value: id,
              child: SizedBox(
                width: 280,
                child: Text(
                  _addressText(address),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          })
          .whereType<DropdownMenuItem<String>>()
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dateTimeCard({
    required String title,
    required DateTime? date,
    required TimeOfDay? time,
    required VoidCallback onDate,
    required VoidCallback onTime,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDate,
                    icon: const Icon(
                      Icons.calendar_today,
                    ),
                    label: Text(
                      _formatDate(date),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTime,
                    icon: const Icon(
                      Icons.access_time,
                    ),
                    label: Text(
                      _formatTime(time),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _addresses.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Please add a saved address before placing an order.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup & Drop-off',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(height: 16),

                          _addressDropdown(
                            label: 'Pickup address',
                            value: _pickupAddressId,
                            onChanged: (value) {
                              setState(() {
                                _pickupAddressId = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          _addressDropdown(
                            label: 'Drop-off address',
                            value: _dropoffAddressId,
                            onChanged: (value) {
                              setState(() {
                                _dropoffAddressId = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          _dateTimeCard(
                            title: 'Pickup',
                            date: _pickupDate,
                            time: _pickupTime,
                            onDate: _selectPickupDate,
                            onTime: _selectPickupTime,
                          ),

                          _dateTimeCard(
                            title: 'Drop-off',
                            date: _dropoffDate,
                            time: _dropoffTime,
                            onDate: _selectDropoffDate,
                            onTime: _selectDropoffTime,
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'Payment',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),

                          RadioGroup<String>(
                            groupValue: _paymentMethod,
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _paymentMethod = value;

                                if (value == 'cash') {
                                  _upiController.clear();
                                }
                              });
                            },
                            child: Column(
                              children: const [
                                RadioListTile<String>(
                                  value: 'cash',
                                  title: Text('Cash'),
                                ),
                                RadioListTile<String>(
                                  value: 'upi',
                                  title: Text('UPI'),
                                ),
                              ],
                            ),
                          ),
                          if (_paymentMethod == 'upi')
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextField(
                                controller: _upiController,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'UPI transaction ID',
                                  border:
                                      OutlineInputBorder(),
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),

                          Text(
                            'Discount code',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _discountController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Optional discount code',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'Special instructions',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'Optional instructions',
                              border:
                                  OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Card(
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  const Text(
                                    'Order Total',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${widget.total.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _placingOrder
                                  ? null
                                  : _placeOrder,
                              child: _placingOrder
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Place Order',
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }
}


