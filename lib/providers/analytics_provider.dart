import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../models/analytics_model.dart';
import '../services/api_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider(this._api);

  final ApiService _api;

  AnalyticsOverview? _overview;
  TrendData? _trendData;
  bool _isLoadingOverview = false;
  bool _isLoadingTrends = false;
  String? _error;
  String _selectedTimeframe = '24h';

  /// Incremented for every trend request; only the latest one may update
  /// the chart, so a slow older response can't overwrite a newer one.
  int _trendRequest = 0;
  Future<void>? _inFlight;
  bool _disposed = false;

  AnalyticsOverview? get overview => _overview;
  TrendData? get trendData => _trendData;
  bool get isLoadingOverview => _isLoadingOverview;
  bool get isLoadingTrends => _isLoadingTrends;
  bool get isLoading => _isLoadingOverview || _isLoadingTrends;
  bool get hasData => _overview != null;
  String? get error => _error;
  String get selectedTimeframe => _selectedTimeframe;

  /// Loads the overview and the trend for the selected timeframe. Calls made
  /// while a load is running share it.
  Future<void> loadData() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    _isLoadingOverview = true;
    _isLoadingTrends = true;
    _error = null;
    _notify();

    final trendRequest = ++_trendRequest;
    final (overview, trends) = await (
      _api.getAnalyticsOverview(),
      _api.getMarketTrends(timeframe: _selectedTimeframe),
    ).wait;
    if (_disposed) return;

    overview.fold(_setError, (data) {
      _overview = data;
    });
    _isLoadingOverview = false;
    if (trendRequest == _trendRequest) {
      trends.fold(_setError, (data) {
        _trendData = data;
      });
      _isLoadingTrends = false;
    }
    _notify();
  }

  Future<void> setTimeframe(String timeframe) async {
    if (_selectedTimeframe == timeframe) return;
    _selectedTimeframe = timeframe;
    final request = ++_trendRequest;
    _isLoadingTrends = true;
    _error = null;
    _notify();

    final result = await _api.getMarketTrends(timeframe: timeframe);
    // A newer request owns the chart now.
    if (_disposed || request != _trendRequest) return;
    result.fold(_setError, (data) {
      _trendData = data;
    });
    _isLoadingTrends = false;
    _notify();
  }

  void _setError(Failure failure) {
    _error = failure.message;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
