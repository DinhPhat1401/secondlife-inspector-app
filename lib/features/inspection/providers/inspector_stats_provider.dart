import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inspector_stats_models.dart';

class InspectorStatsState {
  final int selectedMonth;
  final int selectedYear;
  final InspectorStats? stats;
  final bool isLoadingStats;
  final String? statsError;

  final List<InspectorPayout> payouts;
  final bool isLoadingPayouts;
  final bool isLoadingMorePayouts;
  final String? payoutsError;
  final int payoutsCurrentPage;
  final int payoutsTotalPages;
  final int payoutsTotalElements;
  final String payoutsFilterStatus; // 'ALL', 'SETTLED', 'PENDING'

  const InspectorStatsState({
    required this.selectedMonth,
    required this.selectedYear,
    this.stats,
    this.isLoadingStats = false,
    this.statsError,
    this.payouts = const [],
    this.isLoadingPayouts = false,
    this.isLoadingMorePayouts = false,
    this.payoutsError,
    this.payoutsCurrentPage = 0,
    this.payoutsTotalPages = 1,
    this.payoutsTotalElements = 0,
    this.payoutsFilterStatus = 'ALL',
  });

  List<InspectorPayout> get filteredPayouts {
    if (payoutsFilterStatus == 'ALL') return payouts;
    return payouts.where((p) => p.status == payoutsFilterStatus).toList();
  }

  InspectorStatsState copyWith({
    int? selectedMonth,
    int? selectedYear,
    InspectorStats? stats,
    bool? isLoadingStats,
    String? statsError,
    List<InspectorPayout>? payouts,
    bool? isLoadingPayouts,
    bool? isLoadingMorePayouts,
    String? payoutsError,
    int? payoutsCurrentPage,
    int? payoutsTotalPages,
    int? payoutsTotalElements,
    String? payoutsFilterStatus,
  }) {
    return InspectorStatsState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      stats: stats ?? this.stats,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      statsError: statsError,
      payouts: payouts ?? this.payouts,
      isLoadingPayouts: isLoadingPayouts ?? this.isLoadingPayouts,
      isLoadingMorePayouts: isLoadingMorePayouts ?? this.isLoadingMorePayouts,
      payoutsError: payoutsError,
      payoutsCurrentPage: payoutsCurrentPage ?? this.payoutsCurrentPage,
      payoutsTotalPages: payoutsTotalPages ?? this.payoutsTotalPages,
      payoutsTotalElements: payoutsTotalElements ?? this.payoutsTotalElements,
      payoutsFilterStatus: payoutsFilterStatus ?? this.payoutsFilterStatus,
    );
  }
}

class InspectorStatsNotifier extends Notifier<InspectorStatsState> {
  @override
  InspectorStatsState build() {
    final now = DateTime.now();
    final initialState = InspectorStatsState(
      selectedMonth: now.month,
      selectedYear: now.year,
    );
    Future.microtask(() {
      fetchStats();
      fetchPayouts(page: 0, refresh: true);
    });
    return initialState;
  }

  Future<void> fetchStats({int? month, int? year}) async {
    final targetMonth = month ?? state.selectedMonth;
    final targetYear = year ?? state.selectedYear;
    state = state.copyWith(
      stats: null,
      isLoadingStats: true,
      selectedMonth: targetMonth,
      selectedYear: targetYear,
      statsError: null,
    );
    state = state.copyWith(
      isLoadingStats: false,
      statsError:
          'Backend hiện chưa cung cấp API thống kê/thu nhập cho Inspector. Số liệu chưa thể xác minh.',
    );
  }

  void changeMonthYear(int month, int year) {
    if (state.selectedMonth != month || state.selectedYear != year) {
      fetchStats(month: month, year: year);
    }
  }

  Future<void> fetchPayouts({int page = 0, bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoadingPayouts: true, payoutsError: null);
    } else if (page > 0) {
      state = state.copyWith(isLoadingMorePayouts: true);
    }

    state = state.copyWith(
      payouts: refresh ? const [] : state.payouts,
      isLoadingPayouts: false,
      isLoadingMorePayouts: false,
      payoutsTotalElements: 0,
      payoutsCurrentPage: 0,
      payoutsTotalPages: 1,
      payoutsError:
          'Backend hiện chưa cung cấp API lịch sử đối soát thù lao cho Inspector.',
    );
  }

  Future<void> loadMorePayouts() async {
    if (state.isLoadingPayouts || state.isLoadingMorePayouts) return;
    if (state.payoutsCurrentPage + 1 < state.payoutsTotalPages) {
      await fetchPayouts(page: state.payoutsCurrentPage + 1);
    }
  }

  void setPayoutsFilter(String status) {
    state = state.copyWith(payoutsFilterStatus: status);
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchStats(), fetchPayouts(page: 0, refresh: true)]);
  }
}

final inspectorStatsProvider =
    NotifierProvider<InspectorStatsNotifier, InspectorStatsState>(() {
      return InspectorStatsNotifier();
    });
