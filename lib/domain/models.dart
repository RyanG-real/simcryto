class Coin {
  const Coin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.color,
    required this.sparkline,
  });
  final String id;
  final String name;
  final String symbol;
  final double price;
  final double change24h;
  final int color;
  final List<double> sparkline;
}

class Holding {
  const Holding({
    required this.coinId,
    required this.amount,
    required this.averageCost,
  });
  final String coinId;
  final double amount;
  final double averageCost;
  Holding copyWith({double? amount, double? averageCost}) => Holding(
    coinId: coinId,
    amount: amount ?? this.amount,
    averageCost: averageCost ?? this.averageCost,
  );
}

class TradeRecord {
  TradeRecord({
    required this.id,
    required this.coinId,
    required this.side,
    required this.amount,
    required this.price,
    required this.totalUsd,
    required this.createdAt,
  });
  final String id;
  final String coinId;
  final TradeSide side;
  final double amount;
  final double price;
  final double totalUsd;
  final DateTime createdAt;
}

enum TradeSide { buy, sell }
