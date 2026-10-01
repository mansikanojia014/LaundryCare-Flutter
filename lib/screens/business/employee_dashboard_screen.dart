import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _api.get(ApiConfig.orders);
      final data = response['orders'];

      if (!mounted) return;

      setState(() {
        _orders = data is List
            ? data
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  Future<void> _openOrder(Map<String, dynamic> order) async {
    final id = order['id']?.toString();

    if (id == null || id.isEmpty) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await _api.get(
        '${ApiConfig.orders}/$id',
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmployeeOrderDetailsScreen(
            order: response['order'] is Map
                ? Map<String, dynamic>.from(response['order'])
                : order,
            response: Map<String, dynamic>.from(response),
          ),
        ),
      );

      if (mounted) {
        _loadOrders();
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _api.clearToken();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('ApiException:')) {
      return text.substring('ApiException:'.length).trim();
    }

    return text;
  }

  String _statusLabel(String value) {
    return value
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'washing':
        return Colors.orange;
      case 'ready':
        return Colors.blue;
      case 'out_for_delivery':
        return Colors.deepPurple;
      case 'picked_up':
        return Colors.teal;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.error_outline,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loadOrders,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Icon(
            Icons.local_laundry_service_outlined,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No orders found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'New customer orders will appear here.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 20),
        const Text(
          'Orders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._orders.map(_buildOrderCard),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final active = _orders.where((order) {
      final status = order['status']?.toString();
      return status != 'completed' && status != 'cancelled';
    }).length;

    final pendingPayments = _orders.where((order) {
      final status = order['payment_status']?.toString();
      return status == 'pending' ||
          status == 'verification_pending';
    }).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: _summaryItem(
                Icons.receipt_long,
                'Orders',
                _orders.length.toString(),
              ),
            ),
            Expanded(
              child: _summaryItem(
                Icons.local_shipping,
                'Active',
                active.toString(),
              ),
            ),
            Expanded(
              child: _summaryItem(
                Icons.payments,
                'Payments',
                pendingPayments.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderNumber =
        order['order_number']?.toString() ?? 'Order';

    final status =
        order['status']?.toString() ?? 'received';

    final paymentStatus =
        order['payment_status']?.toString() ?? 'pending';

    final paymentMethod =
        order['payment_method']?.toString() ?? '-';

    final total =
        order['total_amount']?.toString() ?? '0.00';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openOrder(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      orderNumber,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.currency_rupee,
                    size: 18,
                  ),
                  Text(
                    total,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.payment,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _statusLabel(paymentMethod),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Payment: ${_statusLabel(paymentStatus)}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('View Details'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    return Chip(
      label: Text(
        _statusLabel(status),
        style: const TextStyle(fontSize: 12),
      ),
      side: BorderSide.none,
      backgroundColor:
          _statusColor(context, status).withValues(alpha: 0.12),
    );
  }
}

class EmployeeOrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> response;

  const EmployeeOrderDetailsScreen({
    super.key,
    required this.order,
    required this.response,
  });

  @override
  State<EmployeeOrderDetailsScreen> createState() =>
      _EmployeeOrderDetailsScreenState();
}

class _EmployeeOrderDetailsScreenState
    extends State<EmployeeOrderDetailsScreen> {
  final ApiService _api = ApiService();

  late Map<String, dynamic> _order;

  bool _updatingOrderStatus = false;

  static const List<String> _orderStatuses = [
    'received',
    'picked_up',
    'washing',
    'ready',
    'out_for_delivery',
    'completed',
    'cancelled',
  ];

  static const List<String> _paymentStatuses = [
    'pending',
    'paid',
    'verification_pending',
    'failed',
  ];

  @override
  void initState() {
    super.initState();

    _order = Map<String, dynamic>.from(widget.order);
  }

  String _statusLabel(String value) {
    return value
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('ApiException:')) {
      return text.substring('ApiException:'.length).trim();
    }

    return text;
  }

  List<Map<String, dynamic>> _getItems() {
    final items = widget.response['items'];

    if (items is! List) {
      final orderItems = _order['items'];

      if (orderItems is! List) return [];

      return orderItems
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    return items
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  List<Map<String, dynamic>> _getStatusHistory() {
    final history = widget.response['statusHistory'];

    if (history is! List) {
      final orderHistory = _order['status_history'];

      if (orderHistory is! List) return [];

      return orderHistory
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    return history
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  Future<void> _updateOrderStatus(String? status) async {
    if (status == null || status.isEmpty) return;

    final id = _order['id']?.toString();

    if (id == null) return;

    setState(() {
      _updatingOrderStatus = true;
    });

    try {
      final response = await _api.patch(
        '${ApiConfig.orders}/$id/status',
        body: {
          'status': status,
        },
      );

      if (!mounted) return;

      final returnedOrder = response['order'];

      setState(() {
        _order['status'] = returnedOrder is Map
            ? returnedOrder['status'] ?? status
            : status;
        _updatingOrderStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order status updated'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _updatingOrderStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber =
        _order['order_number']?.toString() ?? 'Order Details';

    final status =
        _order['status']?.toString() ?? 'received';

    final paymentStatus =
        _order['payment_status']?.toString() ?? 'pending';

    final paymentMethod =
        _order['payment_method']?.toString() ?? '-';

    final total =
        _order['total_amount']?.toString() ?? '0.00';

    final pickupDate =
        _order['pickup_date']?.toString() ?? '-';

    final pickupTime =
        _order['pickup_time']?.toString() ?? '-';

    final dropoffDate =
        _order['dropoff_date']?.toString() ?? '-';

    final dropoffTime =
        _order['dropoff_time']?.toString() ?? '-';

    final notes =
        _order['notes']?.toString() ?? '';

    final items = _getItems();
    final history = _getStatusHistory();

    return Scaffold(
      appBar: AppBar(
        title: Text(orderNumber),
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionCard(
              title: 'Order Status',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue:
                        _orderStatuses.contains(status)
                            ? status
                            : null,
                    decoration: const InputDecoration(
                      labelText: 'Order status',
                      border: OutlineInputBorder(),
                    ),
                    items: _orderStatuses
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(_statusLabel(item)),
                          ),
                        )
                        .toList(),
                    onChanged: _updatingOrderStatus
                        ? null
                        : _updateOrderStatus,
                  ),
                  if (_updatingOrderStatus)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),

            _sectionCard(
              title: 'Pickup & Drop-off',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                    Icons.calendar_month,
                    'Pickup',
                    '$pickupDate  $pickupTime',
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.local_shipping,
                    'Drop-off',
                    '$dropoffDate  $dropoffTime',
                  ),
                ],
              ),
            ),

            _sectionCard(
              title: 'Items',
              child: items.isEmpty
                  ? const Text('No item details available.')
                  : Column(
                      children: items.map((item) {
                        final cloth =
                            item['cloth_type_name'] ??
                                item['clothTypeName'] ??
                                item['cloth_type'] ??
                                'Cloth';

                        final service =
                            item['service_name'] ??
                                item['serviceName'] ??
                                item['service'] ??
                                'Service';

                        final quantity =
                            item['quantity']?.toString() ?? '0';

                        final lineTotal =
                            item['line_total']?.toString() ??
                                item['lineTotal']?.toString() ??
                                '0.00';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '$cloth ÃƒÂ¯Ã‚Â¿Ã‚Â½ $service',
                          ),
                          subtitle: Text(
                            'Quantity: $quantity piece(s)',
                          ),
                          trailing: Text(
                            '?$lineTotal',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),

            _sectionCard(
              title: 'Order Total',
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '?$total',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            if (notes.isNotEmpty)
              _sectionCard(
                title: 'Special Instructions',
                child: Text(notes),
              ),

            if (history.isNotEmpty)
              _sectionCard(
                title: 'Status History',
                child: Column(
                  children: history.map((item) {
                    final historyStatus =
                        item['status']?.toString() ?? '-';

                    final changedBy =
                        item['changed_by_name'] ??
                            item['changedByName'] ??
                            '';

                    final createdAt =
                        item['created_at']?.toString() ??
                            item['createdAt'] ??
                            '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.check_circle_outline,
                      ),
                      title: Text(
                        _statusLabel(historyStatus),
                      ),
                      subtitle: Text(
                        [
                          changedBy.toString(),
                          createdAt.toString(),
                        ]
                            .where(
                              (value) =>
                                  value.isNotEmpty,
                            )
                            .join(' ÃƒÂ¯Ã‚Â¿Ã‚Â½ '),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}


