import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/market_data_model.dart';
import '../services/api_service.dart';
import '../services/price_feed.dart';

enum SortOption { price, change, symbol }

enum SortOrder { ascending, descending }

/// Market list state: loading, errors, search, sort and live prices.
class MarketDataProvider extends ChangeNotifier {
  MarketDataProvider({
    required ApiService apiService,
    required PriceFeed priceFeed,
    this.throttle = const Duration(milliseconds: 100),
  })  : _api = apiService,
        _feed = priceFeed {
    _feed.status.addListener(_onStatusChanged);
  }

  final ApiService _api;
  final PriceFeed _feed;

  /// Live ticks rebuild the UI at most once per [throttle] window.
  final Duration throttle;

  List<MarketData> _all = const [];
  Map<String, int> _indexBySymbol = const {};
  List<MarketData>? _view;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  Future<void>? _inFlight;
  final Set<String> _refreshingSymbols = {};
  final Map<String, String> _symbolErrors = {};

  bool _realTimeEnabled = false;
  bool _paused = false;
  StreamSubscription<Map<String, dynamic>>? _feedSubscription;
  Timer? _throttleTimer;
  bool _disposed = false;

  String _searchQuery = '';
  SortOption _sortOption = SortOption.price;
  SortOrder _sortOrder = SortOrder.descending;

  /// The searched and sorted list. Computed once per change, not per read.
  List<MarketData> get marketData => _view ??= _buildView();
  SortOption get sortOption => _sortOption;
  SortOrder get sortOrder => _sortOrder;
  String get searchQuery => _searchQuery;
  bool get isFiltering => _searchQuery.trim().isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  /// True when any market is loaded, whatever the search shows.
  bool get hasData => _all.isNotEmpty;

  /// True once a market list load has succeeded (even an empty one).
  bool get hasLoaded => _hasLoaded;
  bool get isRealTimeEnabled => _realTimeEnabled;

  /// Connection state as the user should see it: always disconnected while
  /// live prices are switched off.
  ConnectionStatus get connectionStatus => _realTimeEnabled
      ? _feed.status.value
      : ConnectionStatus.disconnected;

  bool isRefreshing(String symbol) => _refreshingSymbols.contains(symbol);
  String? errorFor(String symbol) => _symbolErrors[symbol];

  MarketData? getBySymbol(String symbol) {
    final index = _indexBySymbol[symbol];
    return index == null ? null : _all[index];
  }

  /// Loads the market list. Calls made while a load is running share it.
  Future<void> loadMarketData() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    _notifyNow();

    final result = await _api.getMarketData();
    if (_disposed) return;
    result.fold(
      (failure) {
        _error = failure.message;
      },
      (data) {
        _hasLoaded = true;
        _setData(data);
      },
    );
    _isLoading = false;
    _notifyNow();
  }

  /// Refreshes a single market (the detail screen) without touching the
  /// list's loading state.
  Future<void> refreshSymbol(String symbol) async {
    if (!_refreshingSymbols.add(symbol)) return;
    _notifyNow();

    final result = await _api.getMarketDataBySymbol(symbol);
    if (_disposed) return;
    _refreshingSymbols.remove(symbol);
    result.fold(
      (failure) {
        _symbolErrors[symbol] = failure.message;
      },
      (data) {
        _symbolErrors.remove(symbol);
        _upsert(data);
      },
    );
    _notifyNow();
  }

  void _setData(List<MarketData> data) {
    _all = List.unmodifiable(data);
    _indexBySymbol = {
      for (var i = 0; i < _all.length; i++) _all[i].symbol: i,
    };
    _view = null;
  }

  void _upsert(MarketData data) {
    final index = _indexBySymbol[data.symbol];
    if (index == null) {
      _setData([..._all, data]);
    } else {
      _replaceAt(index, data);
    }
  }

  void _replaceAt(int index, MarketData data) {
    final next = List.of(_all);
    next[index] = data;
    _all = List.unmodifiable(next);
    _view = null;
  }

  void enableRealTimeUpdates() {
    if (_realTimeEnabled) return;
    _realTimeEnabled = true;
    _feedSubscription ??= _feed.messages.listen(_onMessage);
    if (!_paused) _feed.connect();
    _notifyNow();
  }

  void disableRealTimeUpdates() {
    if (!_realTimeEnabled) return;
    _realTimeEnabled = false;
    _feedSubscription?.cancel();
    _feedSubscription = null;
    _feed.disconnect();
    _notifyNow();
  }

  /// The app went to the background: close the socket, but remember that
  /// the user wants live prices.
  void pauseRealTime() {
    if (_paused) return;
    _paused = true;
    if (_realTimeEnabled) _feed.disconnect();
  }

  /// The app is visible again: reconnect and catch up on missed prices.
  void resumeRealTime() {
    if (!_paused) return;
    _paused = false;
    if (_realTimeEnabled) {
      _feed.connect();
      unawaited(loadMarketData());
    }
  }

  void _onMessage(Map<String, dynamic> message) {
    if (message['type'] != 'market_update') return;
    final data = message['data'];
    if (data is! Map<String, dynamic>) return;
    final symbol = data['symbol'];
    if (symbol is! String) return;
    final index = _indexBySymbol[symbol];
    if (index == null) return;

    _replaceAt(index, MarketData.updateFromJson(_all[index], data));
    _scheduleNotify();
  }

  void _onStatusChanged() {
    if (_realTimeEnabled) _notifyNow();
  }

  /// Throttle, not debounce: however fast ticks arrive, listeners hear about
  /// them at most [throttle] later, so a steady stream can't starve the UI.
  void _scheduleNotify() {
    if (_throttleTimer != null) return;
    _throttleTimer = Timer(throttle, () {
      _throttleTimer = null;
      if (!_disposed) notifyListeners();
    });
  }

  void _notifyNow() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    if (!_disposed) notifyListeners();
  }

  void clearError() {
    _error = null;
    _notifyNow();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _view = null;
    _notifyNow();
  }

  /// Selecting the current option flips the order; a new option starts
  /// descending.
  void setSortOption(SortOption option) {
    if (_sortOption == option) {
      _sortOrder = _sortOrder == SortOrder.ascending
          ? SortOrder.descending
          : SortOrder.ascending;
    } else {
      _sortOption = option;
      _sortOrder = SortOrder.descending;
    }
    _view = null;
    _notifyNow();
  }

  List<MarketData> _buildView() {
    final query = _searchQuery.trim().toLowerCase();
    final list = query.isEmpty
        ? List.of(_all)
        : _all
            .where((item) => item.symbol.toLowerCase().contains(query))
            .toList();

    list.sort((a, b) {
      final comparison = switch (_sortOption) {
        SortOption.price => a.price.compareTo(b.price),
        SortOption.change => a.changePercent24h.compareTo(b.changePercent24h),
        SortOption.symbol => a.symbol.compareTo(b.symbol),
      };
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return List.unmodifiable(list);
  }

  @override
  void dispose() {
    _disposed = true;
    _throttleTimer?.cancel();
    _feedSubscription?.cancel();
    _feed.status.removeListener(_onStatusChanged);
    super.dispose();
  }
}
