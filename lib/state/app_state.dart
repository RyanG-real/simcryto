import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../domain/models.dart';

class AppState extends ChangeNotifier {
  AppState([this._supabase]) {
    final user = _supabase?.auth.currentUser;
    isLoggedIn = user != null;
    isDemo = user?.isAnonymous ?? true;
    if (isLoggedIn) {
      unawaited(refreshMarket());
      unawaited(refreshPortfolio());
    }
    _authSubscription = _supabase?.auth.onAuthStateChange.listen((event) {
      final currentUser = event.session?.user;
      isLoggedIn = currentUser != null;
      isDemo = currentUser?.isAnonymous ?? true;
      if (isLoggedIn) {
        unawaited(refreshMarket());
        unawaited(refreshPortfolio());
      }
      notifyListeners();
    });
    _marketTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isLoggedIn) unawaited(refreshMarket());
    });
  }

  final SupabaseClient? _supabase;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _marketTimer;
  bool isLoggedIn = false;
  bool isLightMode = false;
  bool isDemo = true;
  double cash = 10000;
  bool isMarketRefreshing = false;
  DateTime? lastMarketUpdate;
  String? marketError;
  final Map<String, Holding> holdings = {};
  final List<TradeRecord> transactions = [];

  final List<Coin> coins = [
    Coin(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'BTC',
      price: 83796,
      change24h: -0.82,
      color: 0xFFF7931A,
      sparkline: [4, 5, 4, 6, 5, 7, 6, 8, 12, 11, 13, 12, 14, 10, 9, 8, 10, 9],
    ),
    Coin(
      id: 'ethereum',
      name: 'Ethereum',
      symbol: 'ETH',
      price: 2684.52,
      change24h: -0.08,
      color: 0xFF627EEA,
      sparkline: [4, 6, 5, 8, 7, 10, 8, 9, 7, 6, 8, 7, 9, 8, 7, 6],
    ),
    Coin(
      id: 'tether',
      name: 'Tether',
      symbol: 'USDT',
      price: 0.99977,
      change24h: 0.01,
      color: 0xFF26A17B,
      sparkline: [5, 5, 6, 5, 5, 6, 5, 6, 5, 5, 6, 5],
    ),
    Coin(
      id: 'binancecoin',
      name: 'BNB',
      symbol: 'BNB',
      price: 772.86,
      change24h: -1.04,
      color: 0xFFF3BA2F,
      sparkline: [9, 7, 8, 6, 7, 5, 6, 4, 5, 4, 6, 5],
    ),
    Coin(
      id: 'ripple',
      name: 'XRP',
      symbol: 'XRP',
      price: 1.56,
      change24h: 2.14,
      color: 0xFF4C566A,
      sparkline: [3, 4, 5, 4, 6, 5, 7, 6, 8, 7, 9, 8],
    ),
    Coin(
      id: 'usd-coin',
      name: 'USDC',
      symbol: 'USDC',
      price: 0.99987,
      change24h: 0.01,
      color: 0xFF2775CA,
      sparkline: [5, 5, 5, 6, 5, 5, 6, 5, 5, 6, 5],
    ),
    Coin(
      id: 'solana',
      name: 'Solana',
      symbol: 'SOL',
      price: 121.01,
      change24h: 3.39,
      color: 0xFF9945FF,
      sparkline: [3, 5, 4, 6, 5, 8, 7, 9, 8, 10, 9, 11],
    ),
    Coin(
      id: 'tron',
      name: 'TRON',
      symbol: 'TRX',
      price: 0.33601,
      change24h: -1.59,
      color: 0xFFFF234F,
      sparkline: [10, 8, 9, 7, 8, 6, 7, 5, 6, 4, 5],
    ),
    Coin(
      id: 'zcash',
      name: 'Zcash',
      symbol: 'ZEC',
      price: 1547.33,
      change24h: 0.27,
      color: 0xFFF4B728,
      sparkline: [4, 6, 5, 7, 6, 8, 7, 6, 8, 9, 8],
    ),
    Coin(
      id: 'cardano',
      name: 'Cardano',
      symbol: 'ADA',
      price: 0.89,
      change24h: 1.18,
      color: 0xFF3468D4,
      sparkline: [3, 4, 4, 5, 6, 5, 7, 7, 8, 9],
    ),
  ];

  Coin coinById(String id) => coins.firstWhere((coin) => coin.id == id);
  double get holdingsValue => holdings.values.fold(
    0,
    (sum, item) => sum + item.amount * coinById(item.coinId).price,
  );
  double get totalBalance => cash + holdingsValue;
  bool get isSupabaseConnected => _supabase != null;

  String get accountEmail {
    if (isDemo) return 'demo@cryptosim.app';
    return _supabase?.auth.currentUser?.email ?? 'Google Account';
  }

  String get accountDisplayName {
    if (isDemo) return 'Demo Trader';

    final user = _supabase?.auth.currentUser;
    final metadata = user?.userMetadata;
    for (final key in const ['full_name', 'name', 'display_name']) {
      final value = metadata?[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }

    final emailName = user?.email?.split('@').first.trim();
    if (emailName != null && emailName.isNotEmpty) {
      return emailName
          .split(RegExp(r'[._-]+'))
          .where((part) => part.isNotEmpty)
          .map(
            (part) => part.length == 1
                ? part.toUpperCase()
                : '${part[0].toUpperCase()}${part.substring(1)}',
          )
          .join(' ');
    }
    return 'Crypto Trader';
  }

  String get accountInitial {
    final name = accountDisplayName.trim();
    return name.isEmpty ? 'C' : name.substring(0, 1).toUpperCase();
  }

  Future<String?> login({bool demo = true}) async {
    if (_supabase == null) {
      isLoggedIn = true;
      isDemo = demo;
      notifyListeners();
      return null;
    }
    try {
      if (demo) {
        await _supabase.auth.signInAnonymously();
      } else {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : SupabaseConfig.authRedirectUrl,
          authScreenLaunchMode: kIsWeb
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
        );
      }
      return null;
    } on AuthException catch (error, stackTrace) {
      _logError('sign in', error, stackTrace);
      return error.message;
    } catch (error, stackTrace) {
      _logError('sign in', error, stackTrace);
      return 'Could not sign in: $error';
    }
  }

  Future<void> logout() async {
    if (_supabase != null) {
      await _supabase.auth.signOut();
    } else {
      isLoggedIn = false;
      notifyListeners();
    }
  }

  void toggleTheme(bool light) {
    isLightMode = light;
    notifyListeners();
  }

  Future<void> refreshPortfolio() async {
    if (_supabase == null || _supabase.auth.currentUser == null) return;
    try {
      final profile = await _supabase
          .from('profiles')
          .select('available_cash')
          .single();
      cash = (profile['available_cash'] as num).toDouble();

      final holdingRows = await _supabase
          .from('holdings')
          .select('coin_id, amount, average_cost');
      holdings
        ..clear()
        ..addEntries(
          holdingRows.map((row) {
            final holding = Holding(
              coinId: row['coin_id'] as String,
              amount: (row['amount'] as num).toDouble(),
              averageCost: (row['average_cost'] as num).toDouble(),
            );
            return MapEntry(holding.coinId, holding);
          }),
        );

      final transactionRows = await _supabase
          .from('transactions')
          .select(
            'id, coin_id, side, amount, executed_price, total_usd, created_at',
          )
          .order('created_at', ascending: false);
      transactions
        ..clear()
        ..addAll(
          transactionRows.map(
            (row) => TradeRecord(
              id: row['id'] as String,
              coinId: row['coin_id'] as String,
              side: row['side'] == 'buy' ? TradeSide.buy : TradeSide.sell,
              amount: (row['amount'] as num).toDouble(),
              price: (row['executed_price'] as num).toDouble(),
              totalUsd: (row['total_usd'] as num).toDouble(),
              createdAt: DateTime.parse(row['created_at'] as String),
            ),
          ),
        );
      notifyListeners();
    } catch (error, stackTrace) {
      _logError('refresh portfolio', error, stackTrace);
      // Keep the last known portfolio while the network is unavailable.
    }
  }

  Future<void> refreshMarket() async {
    if (_supabase == null || _supabase.auth.currentUser == null) return;
    if (isMarketRefreshing) return;
    isMarketRefreshing = true;
    marketError = null;
    notifyListeners();
    try {
      final response = await _supabase.functions.invoke('market-data');
      final body = response.data;
      if (body is! Map || body['coins'] is! List) {
        throw const FormatException('Invalid market response');
      }
      final oldColors = {for (final coin in coins) coin.id: coin.color};
      final rows = body['coins'] as List;
      final updated = <Coin>[];
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        if (row is! Map) continue;
        final price = (row['price'] as num?)?.toDouble();
        if (price == null || price <= 0) continue;
        final rawSparkline = (row['sparkline'] as List? ?? const [])
            .whereType<num>()
            .map((value) => value.toDouble())
            .toList();
        final step = rawSparkline.length > 28
            ? (rawSparkline.length / 28).ceil()
            : 1;
        final sparkline = <double>[
          for (var i = 0; i < rawSparkline.length; i += step) rawSparkline[i],
        ];
        final id = row['id'] as String;
        updated.add(
          Coin(
            id: id,
            name: row['name'] as String,
            symbol: row['symbol'] as String,
            price: price,
            change24h: (row['change24h'] as num?)?.toDouble() ?? 0,
            color: oldColors[id] ?? _fallbackCoinColor(index),
            sparkline: sparkline.length >= 2 ? sparkline : [price, price],
          ),
        );
      }
      if (updated.isNotEmpty) {
        coins
          ..clear()
          ..addAll(updated);
        lastMarketUpdate = DateTime.tryParse(
          body['fetchedAt'] as String? ?? '',
        );
      }
    } on FunctionException catch (error, stackTrace) {
      _logError('refresh market', error, stackTrace);
      marketError = error.reasonPhrase ?? 'Market refresh failed';
    } catch (error, stackTrace) {
      _logError('refresh market', error, stackTrace);
      marketError = 'Market refresh failed';
    } finally {
      isMarketRefreshing = false;
      notifyListeners();
    }
  }

  int _fallbackCoinColor(int index) {
    const palette = [
      0xFF16C79A,
      0xFF627EEA,
      0xFFF7931A,
      0xFF9945FF,
      0xFF2775CA,
      0xFFF4B728,
      0xFFFF4161,
      0xFF26A17B,
    ];
    return palette[index % palette.length];
  }

  Future<String?> buy(Coin coin, double usd) async {
    if (usd <= 0) return 'Enter an amount greater than zero';
    if (usd > cash + .000001) return 'Not enough available cash';
    if (_supabase != null) {
      return _executeRemoteTrade(
        coin: coin,
        side: TradeSide.buy,
        inputAmount: usd,
      );
    }
    final amount = usd / coin.price;
    final old = holdings[coin.id];
    if (old == null) {
      holdings[coin.id] = Holding(
        coinId: coin.id,
        amount: amount,
        averageCost: coin.price,
      );
    } else {
      final newAmount = old.amount + amount;
      holdings[coin.id] = old.copyWith(
        amount: newAmount,
        averageCost: ((old.amount * old.averageCost) + usd) / newAmount,
      );
    }
    cash -= usd;
    transactions.insert(
      0,
      TradeRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        coinId: coin.id,
        side: TradeSide.buy,
        amount: amount,
        price: coin.price,
        totalUsd: usd,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return null;
  }

  Future<String?> sell(Coin coin, double amount) async {
    final old = holdings[coin.id];
    if (amount <= 0) {
      return 'Enter an amount greater than zero';
    }
    if (old == null || amount > old.amount + 1e-12) {
      return 'Not enough ${coin.symbol}';
    }
    if (_supabase != null) {
      return _executeRemoteTrade(
        coin: coin,
        side: TradeSide.sell,
        inputAmount: amount,
      );
    }
    final total = amount * coin.price;
    final remaining = old.amount - amount;
    if (remaining < 1e-12) {
      holdings.remove(coin.id);
    } else {
      holdings[coin.id] = old.copyWith(amount: remaining);
    }
    cash += total;
    transactions.insert(
      0,
      TradeRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        coinId: coin.id,
        side: TradeSide.sell,
        amount: amount,
        price: coin.price,
        totalUsd: total,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return null;
  }

  Future<String?> _executeRemoteTrade({
    required Coin coin,
    required TradeSide side,
    required double inputAmount,
  }) async {
    try {
      await _supabase!.functions.invoke(
        'execute-trade',
        body: {
          'client_order_id': const Uuid().v4(),
          'side': side.name,
          'coin_id': coin.id,
          'symbol': coin.symbol,
          'input_amount': inputAmount,
        },
      );
      await refreshPortfolio();
      return null;
    } on FunctionException catch (error, stackTrace) {
      _logError('execute ${side.name} trade', error, stackTrace);
      final details = error.details;
      if (details is Map && details['error'] is String) {
        return details['error'] as String;
      }
      return error.reasonPhrase ?? 'Trade request failed';
    } catch (error, stackTrace) {
      _logError('execute ${side.name} trade', error, stackTrace);
      return 'Trade request failed: $error';
    }
  }

  Future<void> resetAccount() async {
    if (_supabase != null) {
      await _supabase.rpc('reset_my_account');
      await refreshPortfolio();
    } else {
      cash = 10000;
      holdings.clear();
      transactions.clear();
      notifyListeners();
    }
  }

  void _logError(String operation, Object error, StackTrace stackTrace) {
    developer.log(
      '$operation failed',
      name: 'cryptosim.AppState',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    _marketTimer?.cancel();
    super.dispose();
  }
}
