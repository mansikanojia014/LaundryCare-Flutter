import 'package:flutter/material.dart';

import '../../services/order_service.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});
  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadOrders(); }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orders = await _orderService.getMyOrders();
      if (!mounted) return;
      setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = _cleanError(e); });
    }
  }

  Future<void> _openOrder(Map<String, dynamic> order) async {
    final id = order['id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      final response = await _orderService.getOrderDetails(id);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => CustomerOrderTrackingScreen(
          order: response['order'] is Map ? Map<String, dynamic>.from(response['order']) : order,
          response: Map<String, dynamic>.from(response),
        ),
      ));
      if (mounted) _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    }
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final id = order['id']?.toString();
    if (id == null || id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel Order')),
        ],
      ),
    );
    if (confirmed != true) return;
    try { await _orderService.cancelOrder(id); await _loadOrders(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_cleanError(e)))); }
  }

  String _cleanError(Object error) {
    final text = error.toString();
    return text.startsWith('ApiException:') ? text.substring('ApiException:'.length).trim() : text;
  }
  String _value(Map<String, dynamic> order, List<String> keys, [String fallback = '-']) {
    for (final key in keys) { final value = order[key]; if (value != null && value.toString().trim().isNotEmpty) return value.toString(); }
    return fallback;
  }
  String _money(dynamic value) {
    final n = double.tryParse(value?.toString() ?? '');
    return n == null ? value?.toString() ?? '0.00' : n.toStringAsFixed(2);
  }
  String _statusLabel(String value) => value.split('_').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders'), actions: [IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: _loadOrders, child: const Text('Retry'))])))
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 180), Icon(Icons.receipt_long_outlined, size: 56), SizedBox(height: 16), Center(child: Text('No orders yet'))])
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(12), itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final status = _value(order, ['status'], 'received');
                        final number = _value(order, ['order_number', 'orderNumber'], 'Order');
                        final pickup = _value(order, ['pickup_date', 'pickupDate']);
                        final total = _money(order['total_amount'] ?? order['totalAmount'] ?? order['total']);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(onTap: () => _openOrder(order), borderRadius: BorderRadius.circular(16), child: Padding(
                            padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Expanded(child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))), Chip(label: Text(_statusLabel(status)))]),
                              const SizedBox(height: 8), Text('Pickup: $pickup'), const SizedBox(height: 4), Text('Total: ₹$total'), const SizedBox(height: 12),
                              Row(children: [Expanded(child: OutlinedButton(onPressed: () => _openOrder(order), child: const Text('Track Order'))),
                                if (status != 'cancelled' && status != 'completed') ...[const SizedBox(width: 10), Expanded(child: TextButton(onPressed: () => _cancelOrder(order), child: const Text('Cancel')))]
                              ]),
                            ]),
                          )),
                        );
                      },
                    ),
            ),
    );
  }
}

class CustomerOrderTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> response;
  const CustomerOrderTrackingScreen({super.key, required this.order, required this.response});
  String _statusLabel(String value) => value.split('_').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  List<Map<String, dynamic>> _history() {
    final value = response['statusHistory'] ?? order['status_history'];
    if (value is! List) return [];
    return value.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'received';
    final history = _history();
    return Scaffold(appBar: AppBar(title: Text(order['order_number']?.toString() ?? 'Track Order')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [const Icon(Icons.local_shipping_outlined, size: 48), const SizedBox(height: 12), const Text('Current Status', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(_statusLabel(status), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))]))),
        const SizedBox(height: 12),
        if (history.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Status History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
          ...history.map((item) { final s=item['status']?.toString() ?? '-'; final by=item['changed_by_name'] ?? item['changedByName'] ?? ''; final at=item['created_at'] ?? item['createdAt'] ?? ''; return ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle_outline), title: Text(_statusLabel(s)), subtitle: Text([by.toString(), at.toString()].where((v) => v.isNotEmpty).join(' • '))); }),
        ])))
      ]),
    );
  }
}