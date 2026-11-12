import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../models/portfolio_model.dart';
import '../services/api_service.dart';

class PortfolioProvider extends ChangeNotifier {
  PortfolioProvider(this._api);

  final ApiService _api;

  PortfolioOverview? _overview;
  List<PortfolioHolding>? _holdings;
  PortfolioPerformance? _performance;
  bool _isLoadingOverview = false;
  bool _isLoadingHoldings = false;
  bool _isLoadingPerformance = false;
  String? _error;
  String _selectedTimeframe = '24h';

  /// Only the latest performance request may update the data.
  int _performanceRequest = 0;
  Future<void>? _inFlight;
  bool _disposed = false;

  PortfolioOverview? get overview => _overview;
  List<PortfolioHolding>? get holdings => _holdings;
  PortfolioPerformance? get performance => _performance;
  bool get isLoadingPerformance => _isLoadingPerformance;
  bool get isLoading =>
      _isLoadingOverview || _isLoadingHoldings || _isLoadingPerformance;
  bool get hasData => _overview != null;
  String? get error => _error;
  String get selectedTimeframe => _selectedTimeframe;

  /// Loads the overview, holdings and performance. Calls made while a load
  /// is running share it.
  Future<void> loadData() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    _isLoadingOverview = true;
    _isLoadingHoldings = true;
    _isLoadingPerformance = true;
    _error = null;
    _notify();

    final performanceRequest = ++_performanceRequest;
    final (overview, holdings, performance) = await (
      _api.getPortfolioOverview(),
      _api.getPortfolioHoldings(),
      _api.getPortfolioPerformance(timeframe: _selectedTimeframe),
    ).wait;
    if (_disposed) return;

    overview.fold(_setError, (data) {
      _overview = data;
    });
    holdings.fold(_setError, (data) {
      _holdings = data;
    });
    _isLoadingOverview = false;
    _isLoadingHoldings = false;
    if (performanceRequest == _performanceRequest) {
      performance.fold(_setError, (data) {
        _performance = data;
      });
      _isLoadingPerformance = false;
    }
    _notify();
  }

  Future<void> setTimeframe(String timeframe) async {
    if (_selectedTimeframe == timeframe) return;
    _selectedTimeframe = timeframe;
    final request = ++_performanceRequest;
    _isLoadingPerformance = true;
    _error = null;
    _notify();

    final result =
        await _api.getPortfolioPerformance(timeframe: timeframe);
    if (_disposed || request != _performanceRequest) return;
    result.fold(_setError, (data) {
      _performance = data;
    });
    _isLoadingPerformance = false;
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
