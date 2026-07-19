import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _codeCtrl = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final Animation<double> _cardAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);

    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutBack);
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _focusNode.dispose();
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      _shake();
      return;
    }
    final provider = context.read<AppProvider>();
    final error = await provider.activate(code);
    if (error != null) {
      if (mounted) {
        _shake();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.liveColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  void _shake() {
    _cardCtrl.forward(from: 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0xFF0A0E1A),
                  Color(0xFF111827),
                  Color(0xFF0F1629),
                ],
                stops: [
                  0.0,
                  _bgCtrl.value * 0.5 + 0.3,
                  1.0,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ScaleTransition(
                scale: _cardAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    _buildLogo(),
                    const SizedBox(height: 48),
                    // Card
                    _buildCard(provider),
                    const SizedBox(height: 32),
                    // Footer
                    const Text(
                      'ELKHALFY IPTV © 2025',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ELKHALFY',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryColor, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'I P T V',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.primaryColor,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تفعيل الاشتراك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أدخل كود التفعيل الخاص بك',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 28),
          // Code input
          TextField(
            controller: _codeCtrl,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _activate(),
            decoration: InputDecoration(
              hintText: 'XXXX-XXXX',
              hintStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 22,
                letterSpacing: 4,
              ),
              prefixIcon: const Icon(Icons.vpn_key_rounded,
                  color: AppTheme.primaryColor),
              filled: true,
              fillColor: AppTheme.bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : _activate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_fill_rounded,
                                color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'تفعيل',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
}
