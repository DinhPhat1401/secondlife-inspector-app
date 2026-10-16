import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
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
  final ApiClient _api = ApiClient();

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
      isLoadingStats: true,
      selectedMonth: targetMonth,
      selectedYear: targetYear,
    );

    try {
      final response = await _api.dio.get(
        ApiEndpoints.inspectorStats,
        queryParameters: {
          'month': targetMonth,
          'year': targetYear,
        },
      );

      final raw = response.data;
      final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      if (data is Map<String, dynamic>) {
        final stats = InspectorStats.fromJson(data);
        state = state.copyWith(
          stats: stats,
          isLoadingStats: false,
          statsError: null,
        );
      } else {
        state = state.copyWith(
          isLoadingStats: false,
          statsError: 'Dữ liệu thống kê không hợp lệ',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingStats: false,
        statsError: 'Không thể tải thống kê: $e',
      );
    }
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

    try {
      final response = await _api.dio.get(
        ApiEndpoints.inspectorPayouts,
        queryParameters: {
          'page': page,
          'size': 10,
          'sort': 'completedAt,desc',
        },
      );

      final raw = response.data;
      final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      if (data is Map<String, dynamic>) {
        final payoutsPage = InspectorPayoutsPage.fromJson(data);
        final currentList = refresh ? <InspectorPayout>[] : List<InspectorPayout>.from(state.payouts);
        
        // Append or replace
        for (final item in payoutsPage.content) {
          if (!currentList.any((p) => p.payoutId == item.payoutId)) {
            currentList.add(item);
          }
        }

        state = state.copyWith(
          payouts: currentList,
          isLoadingPayouts: false,
          isLoadingMorePayouts: false,
          payoutsCurrentPage: payoutsPage.pageNumber,
          payoutsTotalPages: payoutsPage.totalPages,
          payoutsTotalElements: payoutsPage.totalElements,
          payoutsError: null,
        );
      } else {
        state = state.copyWith(
          isLoadingPayouts: false,
          isLoadingMorePayouts: false,
          payoutsError: 'Dữ liệu đối soát không hợp lệ',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingPayouts: false,
        isLoadingMorePayouts: false,
        payoutsError: 'Không thể tải lịch sử đối soát: $e',
      );
    }
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
    await Future.wait([
      fetchStats(),
      fetchPayouts(page: 0, refresh: true),
    ]);
  }
}

final inspectorStatsProvider =
    NotifierProvider<InspectorStatsNotifier, InspectorStatsState>(() {
  return InspectorStatsNotifier();
});
