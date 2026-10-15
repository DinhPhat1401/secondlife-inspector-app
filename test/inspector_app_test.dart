import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secondlife_app_inspector/features/inspection/models/checklist_item.dart';
import 'package:secondlife_app_inspector/features/inspection/models/inspection_order.dart';
import 'package:secondlife_app_inspector/features/inspection/models/tamper_seal.dart';
import 'package:secondlife_app_inspector/features/inspection/providers/inspection_provider.dart';

void main() {
  group('ChecklistItem Model Tests', () {
    test('ChecklistItem parsing and result serialization', () {
      final item = ChecklistItem(
        id: 'chk-power',
        itemTitle: 'Nguồn điện & Tiếp địa',
        criteriaDescription: 'Kiểm tra chống rò rỉ điện',
        mandatory: true,
        passed: true,
        inspectorNote: 'Điện áp 220V ổn định, tiếp địa chuẩn',
      );

      final jsonResult = item.toResultJson();
      expect(jsonResult['itemId'], 'chk-power');
      expect(jsonResult['passed'], true);
      expect(jsonResult['inspectorNote'], 'Điện áp 220V ổn định, tiếp địa chuẩn');
    });

    test('ChecklistItem copyWith updates values correctly', () {
      final item = ChecklistItem(
        id: 'chk-motor',
        itemTitle: 'Động cơ',
        criteriaDescription: 'Kiểm tra độ ồn',
      );

      final updated = item.copyWith(passed: false, inspectorNote: 'Kêu to');
      expect(updated.passed, false);
      expect(updated.inspectorNote, 'Kêu to');
      expect(updated.id, 'chk-motor');
    });
  });

  group('TamperSeal Model Tests', () {
    test('InspectionSealVerification parsing', () {
      final cert = InspectionSealVerification(
        tamperSealId: 'SL-SEAL-8924-A1',
        productTitle: 'Máy Lạnh Inverter Daikin',
        conditionScore: 94,
        conditionGrade: 'A - Rất Tốt',
        inspectionStatus: 'PASSED',
        currentSealStatus: 'INTACT',
        isOfficialSecondLifeSeal: true,
      );

      expect(cert.tamperSealId, 'SL-SEAL-8924-A1');
      expect(cert.isIntact, true);
      expect(cert.conditionScore, 94);
    });

    test('InspectionSealLog parsing and stages', () {
      final log = InspectionSealLog(
        id: 'log-101',
        tamperSealId: 'SL-SEAL-8924-A1',
        scanStage: 'INITIAL_SEAL',
        sealCondition: 'INTACT',
        scannedAt: DateTime.now(),
      );

      expect(log.scanStageLabel, contains('Dán tem niêm phong ban đầu'));
      expect(log.isIntact, true);
    });
  });

  group('InspectionOrder Model Tests', () {
    test('InspectionOrder calculations and at-home status', () {
      final order = InspectionOrder(
        id: 'INS-01',
        postTitle: 'Tủ Lạnh Panasonic 540L',
        postPrice: 15000000,
        sellerName: 'Nguyễn Văn A',
        buyerName: 'Trần Văn B',
        orderType: 'AT_HOME',
        feePayer: 'SPLIT_50_50',
        status: 'SCHEDULED',
        inspectionFee: 250000,
        travelDistanceKm: 6.2,
        travelFee: 65000,
      );

      expect(order.isAtHome, true);
      expect(order.statusLabel, 'Đã lên lịch hẹn');
      expect(order.travelFee, 65000);
    });
  });

  group('InspectionNotifier State & Filter Tests', () {
    test('Notifier filters and search works as expected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(inspectionProvider);
      expect(state.orders.isNotEmpty, true);

      final notifier = container.read(inspectionProvider.notifier);

      // Filter by SCHEDULED
      notifier.setFilter('SCHEDULED');
      final scheduledState = container.read(inspectionProvider);
      expect(scheduledState.activeFilter, 'SCHEDULED');
      for (final order in scheduledState.filteredOrders) {
        expect(order.status == 'SCHEDULED' || order.status == 'CONFIRMED_PENDING_DISPATCH', true);
      }

      // Search by query
      notifier.setFilter('ALL');
      notifier.setSearchQuery('Daikin');
      final searchState = container.read(inspectionProvider);
      expect(searchState.filteredOrders.length, 1);
      expect(searchState.filteredOrders.first.postTitle, contains('Daikin'));
    });

    test('Updating checklist item updates state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(inspectionProvider.notifier);
      notifier.updateChecklistItem('chk-01', true, 'Vỏ máy đẹp', null);

      final state = container.read(inspectionProvider);
      final item = state.currentChecklist.firstWhere((i) => i.id == 'chk-01');
      expect(item.passed, true);
      expect(item.inspectorNote, 'Vỏ máy đẹp');
    });

    test('Submit inspection result updates order to PASSED with seal and score', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(inspectionProvider.notifier);
      final firstOrderId = container.read(inspectionProvider).orders.first.id;

      final ok = await notifier.submitInspectionResult(
        orderId: firstOrderId,
        status: 'PASSED',
        conditionScore: 95,
        conditionGrade: 'S - Nguyên Bản Mới',
        tamperSealId: 'SL-SEAL-TEST-99',
        note: 'Đạt chuẩn',
      );

      expect(ok, true);
      final state = container.read(inspectionProvider);
      final updatedOrder = state.orders.firstWhere((o) => o.id == firstOrderId);
      expect(updatedOrder.status, 'PASSED');
      expect(updatedOrder.conditionScore, 95);
      expect(updatedOrder.tamperSealId, 'SL-SEAL-TEST-99');
    });

    test('Verify seal and record seal scan', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(inspectionProvider.notifier);

      final cert = await notifier.verifySeal('SL-SEAL-8924-A1');
      expect(cert, isNotNull);
      expect(cert!.tamperSealId, 'SL-SEAL-8924-A1');
      expect(cert.isIntact, true);

      final recordOk = await notifier.recordSealScan(
        tamperSealId: 'SL-SEAL-8924-A1',
        scanStage: 'CARRIER_HANDOVER',
        sealCondition: 'INTACT',
        locationText: 'Kho chuyển phát nhanh',
        note: 'Tem còn nguyên vẹn',
      );
      expect(recordOk, true);

      final state = container.read(inspectionProvider);
      expect(state.verifiedSeal!.scanHistory.length, greaterThanOrEqualTo(2));
    });
  });
}
