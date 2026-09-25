import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../domain/models.dart';
import '../state/app_state.dart';
import '../widgets/sparkline.dart';

Future<void> showTradeSheet(BuildContext context, Coin coin) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: TradeSheet(coin: coin),
      ),
    );

class TradeSheet extends StatefulWidget {
  const TradeSheet({super.key, required this.coin});
  final Coin coin;
  @override
  State<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<TradeSheet> {
  final controller = TextEditingController();
  bool buying = true;
  bool loading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  double get input => double.tryParse(controller.text.replaceAll(',', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final coin = widget.coin;
    final holding = state.holdings[coin.id];
    final positive = coin.change24h >= 0;
    final number = NumberFormat('#,##0.00####');
    final result = buying ? input / coin.price : input * coin.price;
    return DraggableScrollableSheet(
      initialChildSize: .88,
      minChildSize: .58,
      maxChildSize: .96,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.border),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: .4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _CoinLogo(coin: coin, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coin.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        coin.symbol,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${number.format(coin.price)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${positive ? '+' : ''}${coin.change24h.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: positive ? AppColors.mint : AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 170,
              child: Sparkline(
                values: coin.sparkline,
                color: positive ? AppColors.mint : AppColors.danger,
                fill: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(
                  label: '24H HIGH',
                  value: '\$${number.format(coin.price * 1.017)}',
                ),
                _Stat(
                  label: '24H LOW',
                  value: '\$${number.format(coin.price * .993)}',
                ),
                const _Stat(label: 'VOLUME', value: '\$37.54B'),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _ModeButton(
                    label: 'Buy',
                    active: buying,
                    onTap: () => setState(() {
                      buying = true;
                      controller.clear();
                    }),
                  ),
                  _ModeButton(
                    label: 'Sell',
                    active: !buying,
                    onTap: () => setState(() {
                      buying = false;
                      controller.clear();
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              buying
                  ? 'Cash: \$${number.format(state.cash)}'
                  : 'Available: ${number.format(holding?.amount ?? 0)} ${coin.symbol}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: false,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: buying ? 'USD  ' : '${coin.symbol}  ',
                suffixIcon: TextButton(
                  onPressed: () {
                    controller.text = buying
                        ? state.cash.toStringAsFixed(2)
                        : (holding?.amount ?? 0).toStringAsFixed(8);
                    setState(() {});
                  },
                  child: const Text('MAX'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [.25, .5, .75]
                  .map(
                    (ratio) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () {
                            final max = buying
                                ? state.cash
                                : holding?.amount ?? 0;
                            controller.text = (max * ratio).toStringAsFixed(
                              buying ? 2 : 8,
                            );
                            setState(() {});
                          },
                          child: Text('${(ratio * 100).round()}%'),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    buying ? 'You receive' : 'You receive',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const Spacer(),
                  Text(
                    buying
                        ? '${number.format(result)} ${coin.symbol}'
                        : '\$${number.format(result)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: loading || input <= 0 ? null : () => _submit(state),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'CONFIRM ${buying ? 'BUY' : 'SELL'}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Market prices are simulated and may be delayed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(AppState state) async {
    setState(() => loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final error = buying
        ? await state.buy(widget.coin, input)
        : await state.sell(widget.coin, input);
    if (!mounted) return;
    setState(() => loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final amount = buying ? input / widget.coin.price : input;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.mint,
        content: Text(
          '${buying ? 'Bought' : 'Sold'} ${amount.toStringAsFixed(8)} ${widget.coin.symbol}',
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.mint : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: active ? AppColors.navy : AppColors.muted,
          ),
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _CoinLogo extends StatelessWidget {
  const _CoinLogo({required this.coin, required this.size});
  final Coin coin;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: Color(coin.color), shape: BoxShape.circle),
    child: Text(
      coin.symbol.substring(0, 1),
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: size * .42,
      ),
    ),
  );
}
