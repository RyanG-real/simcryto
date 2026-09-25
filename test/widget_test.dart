import 'package:cryptosim/app.dart';
import 'package:cryptosim/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('opens demo portfolio', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const CryptoSimApp(),
      ),
    );

    expect(find.text('Try Demo'), findsOneWidget);
    await tester.tap(find.text('Try Demo'));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL PORTFOLIO VALUE'), findsOneWidget);
    expect(find.text('No holdings yet'), findsOneWidget);
  });
}
