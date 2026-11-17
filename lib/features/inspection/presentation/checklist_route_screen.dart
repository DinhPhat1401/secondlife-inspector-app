import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inspection_order.dart';
import '../providers/inspection_provider.dart';
import 'checklist_execution_screen.dart';

class ChecklistRouteScreen extends ConsumerStatefulWidget {
  const ChecklistRouteScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<ChecklistRouteScreen> createState() =>
      _ChecklistRouteScreenState();
}

class _ChecklistRouteScreenState extends ConsumerState<ChecklistRouteScreen> {
  InspectionOrder? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final order = await ref
        .read(inspectionProvider.notifier)
        .fetchOrderDetail(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = order;
      _isLoading = false;
      if (order == null) {
        _error = 'Không tải được đơn kiểm định. Vui lòng thử lại.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order != null) return ChecklistExecutionScreen(order: order);

    return Scaffold(
      appBar: AppBar(title: const Text('Checklist kiểm định')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 44),
                    const SizedBox(height: 12),
                    Text(_error ?? 'Không tìm thấy đơn kiểm định.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadOrder,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
