import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../models/inspection_order.dart';
import '../providers/inspection_provider.dart';

class MapRouteScreen extends ConsumerStatefulWidget {
  const MapRouteScreen({super.key});

  @override
  ConsumerState<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends ConsumerState<MapRouteScreen> {
  final MapController _mapController = MapController();
  final LatLng _inspectorLocation = const LatLng(10.8490, 106.7750); // Thu Duc Hub
  InspectionOrder? _selectedOrderOnMap;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionProvider);
    final orders = state.orders;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản Đồ Di Chuyển & Điểm Kiểm Định'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Vị trí của tôi',
            onPressed: () {
              _mapController.move(_inspectorLocation, 14.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _inspectorLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.secondlife.secondlife_app_inspector',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _inspectorLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                  ...orders.map((order) {
                    final isSelected = _selectedOrderOnMap?.id == order.id;
                    return Marker(
                      point: LatLng(order.latitude, order.longitude),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedOrderOnMap = order);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secondary
                                : (order.isAtHome ? AppColors.mapBlue : Colors.purple),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            order.isAtHome ? Icons.home_repair_service : Icons.business,
                            color: Colors.white,
                            size: isSelected ? 26 : 22,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hiện có ${orders.where((o) => o.status == "SCHEDULED" || o.status == "INSPECTING").length} địa điểm cần di chuyển hôm nay',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.slate800),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_selectedOrderOnMap != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${_selectedOrderOnMap!.id}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedOrderOnMap!.postTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _selectedOrderOnMap = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 16, color: AppColors.slate500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedOrderOnMap!.sellerAddress ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.directions_bike, size: 16, color: AppColors.mapBlue),
                          const SizedBox(width: 4),
                          Text(
                            'Cách ${_selectedOrderOnMap!.travelDistanceKm} km',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mapBlue, fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            'Phụ cấp: +${currencyFormatter.format(_selectedOrderOnMap!.travelFee)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.passGreen, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _mapController.move(
                                  LatLng(_selectedOrderOnMap!.latitude, _selectedOrderOnMap!.longitude),
                                  15.0,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text('Định Vị'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ref.read(inspectionProvider.notifier).selectOrder(_selectedOrderOnMap!);
                                context.push('/order-detail', extra: _selectedOrderOnMap);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text('Xem Chi Tiết'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
