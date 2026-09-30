import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class BusinessOrdersScreen extends StatefulWidget {
  const BusinessOrdersScreen({super.key});

  @override
  State<BusinessOrdersScreen> createState() => _BusinessOrdersScreenState();
}

class _BusinessOrdersScreenState extends State<BusinessOrdersScreen> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  final List<String> _statuses = [
    'received',
    'picked_up',
    'washing',
    'ready',
    'out_for_delivery',
    'completed',
    'cancelled',
  ];

  final List<String> _paymentStatuses = [
    'pending',
    'paid',
    'verification_pending',
    'failed',
  ];

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

      if (data is List) {
        _orders = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _orders = [];
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

  Future<void> _openOrder(Map<String, dynamic> order) async {
    final id = order['id']?.toString();

    if (id == null || id.isEmpty) {
      return;
    }

    try {
      final response = await _api.get('${ApiConfig.orders}/$id');

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessOrderDetailsScreen(
            order: Map<String, dynamic>.from(
              response['order'] is Map
                  ? response['order']
                  : response,
            ),
            api: _api,
            statuses: _statuses,
            paymentStatuses: _paymentStatuses,
          ),
        ),
      );

      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _displayStatus(String? value) {
    if (value == null || value.isEmpty) return 'Unknown';

    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
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
                'Unable to load orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(Icons.receipt_long, size: 60),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No orders found',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];

          final orderNumber =
              order['order_number']?.toString() ??
              order['orderNumber']?.toString() ??
              'Order ${index + 1}';

          final status = order['status']?.toString() ?? 'received';
          final paymentStatus =
              order['payment_status']?.toString() ??
              order['paymentStatus']?.toString() ??
              'pending';

          final total =
              order['total_amount']?.toString() ??
              order['totalAmount']?.toString() ??
              '0.00';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(
                orderNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_displayStatus(status)}\n'
                  'Payment: ${_displayStatus(paymentStatus)}\n'
                  'Total: ₹$total',
                ),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openOrder(order),
            ),
          );
        },
      ),
    );
  }
}

class BusinessOrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final ApiService api;
  final List<String> statuses;
  final List<String> paymentStatuses;

  const BusinessOrderDetailsScreen({
    super.key,
    required this.order,
    required this.api,
    required this.statuses,
    required this.paymentStatuses,
  });

  @override
  State<BusinessOrderDetailsScreen> createState() =>
      _BusinessOrderDetailsScreenState();
}

class _BusinessOrderDetailsScreenState
    extends State<BusinessOrderDetailsScreen> {
  bool _updatingStatus = false;
  bool _updatingPayment = false;

  String _displayStatus(String? value) {
    if (value == null || value.isEmpty) return 'Unknown';

    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String? _value(String snake, String camel) {
    return widget.order[snake]?.toString() ??
        widget.order[camel]?.toString();
  }

  Future<void> _updateOrderStatus(String status) async {
    final id = widget.order['id']?.toString();

    if (id == null) return;

    setState(() {
      _updatingStatus = true;
    });

    try {
      final response = await widget.api.patch(
        '${ApiConfig.orders}/$id/status',
        body: {
          'status': status,
        },
      );

      final updatedOrder = response['order'];

      if (updatedOrder is Map) {
        widget.order
          ..clear()
          ..addAll(Map<String, dynamic>.from(updatedOrder));
      } else {
        widget.order['status'] = status;
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order status updated to ${_displayStatus(status)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingStatus = false;
        });
      }
    }
  }

  Future<void> _updatePaymentStatus(String status) async {
    final id = widget.order['id']?.toString();

    if (id == null) return;

    setState(() {
      _updatingPayment = true;
    });

    try {
      final response = await widget.api.patch(
        '${ApiConfig.orders}/$id/payment-status',
        body: {
          'paymentStatus': status,
        },
      );

      final updatedOrder = response['order'];

      if (updatedOrder is Map) {
        widget.order
          ..clear()
          ..addAll(Map<String, dynamic>.from(updatedOrder));
      } else {
        widget.order['payment_status'] = status;
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment status updated to ${_displayStatus(status)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingPayment = false;
        });
      }
    }
  }

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _itemsSection() {
    final items = widget.order['items'];

    if (items is! List || items.isEmpty) {
      return const Text('No item details available.');
    }

    return Column(
      children: items.map<Widget>((item) {
        final data = Map<String, dynamic>.from(item);

        final cloth =
            data['cloth_type_name']?.toString() ??
            data['clothTypeName']?.toString() ??
            'Cloth';

        final service =
            data['service_name']?.toString() ??
            data['serviceName']?.toString() ??
            'Service';

        final quantity =
            data['quantity']?.toString() ?? '0';

        final lineTotal =
            data['line_total']?.toString() ??
            data['lineTotal']?.toString() ??
            '0.00';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('$cloth - $service'),
            subtitle: Text('Quantity: $quantity pieces'),
            trailing: Text(
              '₹$lineTotal',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber =
        _value('order_number', 'orderNumber') ?? 'Order';

    final status =
        _value('status', 'status') ?? 'received';

    final paymentStatus =
        _value('payment_status', 'paymentStatus') ?? 'pending';

    final paymentMethod =
        _value('payment_method', 'paymentMethod') ?? '-';

    final total =
        _value('total_amount', 'totalAmount') ?? '0.00';

    return Scaffold(
      appBar: AppBar(
        title: Text(orderNumber),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            orderNumber,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Order Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _info('Status', _displayStatus(status)),
          _info('Payment', _displayStatus(paymentStatus)),
          _info('Method', _displayStatus(paymentMethod)),
          _info('Total', '₹$total'),

          const SizedBox(height: 20),

          const Text(
            'Order Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _itemsSection(),

          const SizedBox(height: 24),

          const Text(
            'Update Order Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: widget.statuses.contains(status)
                ? status
                : widget.statuses.first,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Order Status',
            ),
            items: widget.statuses
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_displayStatus(value)),
                  ),
                )
                .toList(),
            onChanged: _updatingStatus
                ? null
                : (value) {
                    if (value != null && value != status) {
                      _updateOrderStatus(value);
                    }
                  },
          ),

          if (_updatingStatus)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(),
            ),

          const SizedBox(height: 24),

          const Text(
            'Update Payment Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: widget.paymentStatuses.contains(paymentStatus)
                ? paymentStatus
                : widget.paymentStatuses.first,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Payment Status',
            ),
            items: widget.paymentStatuses
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_displayStatus(value)),
                  ),
                )
                .toList(),
            onChanged: _updatingPayment
                ? null
                : (value) {
                    if (value != null && value != paymentStatus) {
                      _updatePaymentStatus(value);
                    }
                  },
          ),

          if (_updatingPayment)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
