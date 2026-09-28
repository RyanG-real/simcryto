import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../state/app_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.mint, Color(0xFF18AEE0)],
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.view_in_ar_outlined,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(text: 'Crypto'),
                            TextSpan(
                              text: 'Sim',
                              style: TextStyle(color: AppColors.mint),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const _BenefitCard(),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: () => _login(context, demo: false),
                          icon: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => _login(context, demo: true),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: const Text('Try Demo'),
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login(BuildContext context, {required bool demo}) async {
    final error = await context.read<AppState>().login(demo: demo);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: const Column(
      children: [
        _Benefit(icon: '💰', text: 'Start with \$10,000 virtual cash'),
        SizedBox(height: 16),
        _Benefit(icon: '📈', text: 'Live prices from CoinGecko'),
        SizedBox(height: 16),
        _Benefit(icon: '🔒', text: 'No real money ever at risk'),
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final String icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(icon),
      const SizedBox(width: 14),
      Expanded(
        child: Text(text, style: const TextStyle(color: AppColors.muted)),
      ),
    ],
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: .23)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
