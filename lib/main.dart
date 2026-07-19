import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/storage_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bgColor,
  ));
  runApp(const ElkhalfyApp());
}

class ElkhalfyApp extends StatelessWidget {
  const ElkhalfyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'ELKHALFY IPTV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashRouter(),
      ),
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim =
        Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    ));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
    _checkSession();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final savedCode = StorageService.getActivationCode();
    if (savedCode != null && savedCode.isNotEmpty) {
      final provider = context.read<AppProvider>();
      final ok = await provider.loadFromSavedCode(savedCode);
      if (mounted) {
        _navigate(ok ? const MainScreen() : const LoginScreen());
      }
    } else {
      if (mounted) _navigate(const LoginScreen());
    }
  }

  void _navigate(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text('K',
                          style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ELKHALFY',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'I P T V',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 180,
                    child: LinearProgressIndicator(
                      backgroundColor: AppTheme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor),
                      minHeight: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
