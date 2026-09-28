import 'package:cryptosim/domain/models.dart';
import 'package:cryptosim/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppState state;

  setUp(() {
    state = AppState();
  });

  tearDown(() {
    state.dispose();
  });

  group('authentication', () {
    test('demo login and logout update authentication state', () async {
      expect(state.isLoggedIn, isFalse);

      expect(await state.login(), isNull);
      expect(state.isLoggedIn, isTrue);
      expect(state.isDemo, isTrue);

      await state.logout();
      expect(state.isLoggedIn, isFalse);
    });

    test('Google login selects non-demo mode in local fallback', () async {
      expect(await state.login(demo: false), isNull);

      expect(state.isLoggedIn, isTrue);
      expect(state.isDemo, isFalse);
      expect(state.accountDisplayName, 'Crypto Trader');
      expect(state.accountEmail, 'Google Account');
    });
  });

  group('trading', () {
    const bitcoinAt100 = Coin(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'BTC',
      price: 100,
      change24h: 0,
      color: 0,
      sparkline: [100, 100],
    );
    const bitcoinAt120 = Coin(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'BTC',
      price: 120,
      change24h: 20,
      color: 0,
      sparkline: [100, 120],
    );
    const bitcoinAt200 = Coin(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'BTC',
      price: 200,
      change24h: 100,
      color: 0,
      sparkline: [100, 200],
    );

    test('buy deducts cash and calculates weighted average cost', () async {
      expect(await state.buy(bitcoinAt100, 100), isNull);
      expect(await state.buy(bitcoinAt200, 200), isNull);

      final holding = state.holdings['bitcoin']!;
      expect(state.cash, closeTo(9700, 1e-9));
      expect(holding.amount, closeTo(2, 1e-9));
      expect(holding.averageCost, closeTo(150, 1e-9));
      expect(state.transactions, hasLength(2));
      expect(state.transactions.first.side, TradeSide.buy);
    });

    test('sell credits cash, reduces holding and records a sell', () async {
      await state.buy(bitcoinAt100, 100);

      expect(await state.sell(bitcoinAt120, 0.4), isNull);

      expect(state.cash, closeTo(9948, 1e-9));
      expect(state.holdings['bitcoin']!.amount, closeTo(0.6, 1e-9));
      expect(state.transactions.first.side, TradeSide.sell);
      expect(state.transactions.first.totalUsd, closeTo(48, 1e-9));
    });

    test('buy and sell reject invalid balances', () async {
      expect(await state.buy(bitcoinAt100, 10001), isNotNull);
      expect(await state.sell(bitcoinAt100, 1), 'Not enough BTC');
      expect(state.transactions, isEmpty);
    });
  });

  test('reset restores starting cash and clears account activity', () async {
    const coin = Coin(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'BTC',
      price: 100,
      change24h: 0,
      color: 0,
      sparkline: [100, 100],
    );
    await state.buy(coin, 500);

    await state.resetAccount();

    expect(state.cash, 10000);
    expect(state.holdings, isEmpty);
    expect(state.transactions, isEmpty);
  });
}
