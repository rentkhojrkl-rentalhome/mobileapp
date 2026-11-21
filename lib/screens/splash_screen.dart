import 'package:flutter/material.dart';

/// Displays the exact RentKhojRKL splash artwork supplied by the owner.
/// The artwork itself is kept unchanged; Flutter animates its entrance and
/// applies a subtle cinematic zoom before the existing AuthGate is shown.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4400),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, .22, curve: Curves.easeOut),
  );

  late final Animation<double> _zoom = Tween<double>(
    begin: 1.045,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 1, curve: Curves.easeOutCubic),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FFF9),
      body: SizedBox.expand(
        child: ClipRect(
          child: FadeTransition(
            opacity: _fade,
            child: AnimatedBuilder(
              animation: _zoom,
              builder: (context, child) {
                return Transform.scale(
                  scale: _zoom.value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/rentkhoj_splash.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'RentKhojRKL',
                      style: TextStyle(
                        color: Color(0xFF07583C),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
