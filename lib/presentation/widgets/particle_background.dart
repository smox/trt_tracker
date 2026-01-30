import 'dart:math';
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  // --- KONFIGURATION ---
  // Hier kannst du die Geschwindigkeit einstellen!
  // 1.0 = Schnell (wie vorher)
  // 0.5 = Halb so schnell
  // 0.1 = Sehr langsam (Zeitlupe)
  static const double globalSpeedFactor = 0.15;

  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(_updateParticles);

    for (int i = 0; i < 25; i++) {
      _particles.add(_generateParticle(randomY: true));
    }
  }

  void _updateParticles() {
    for (var particle in _particles) {
      // Bewegung nach oben
      // Wir multiplizieren die individuelle Partikel-Geschwindigkeit mit deinem Faktor
      double moveAmount = (particle.speed * 0.01) * globalSpeedFactor;

      particle.y -= moveAmount;

      if (particle.y < -0.1) {
        particle.y = 1.1;
        particle.x = _random.nextDouble();
      }
    }
    setState(() {});
  }

  Particle _generateParticle({bool randomY = false}) {
    return Particle(
      x: _random.nextDouble(),
      y: randomY ? _random.nextDouble() : 1.1,
      // Basis-Geschwindigkeit (Variation zwischen den Partikeln)
      speed: 0.2 + _random.nextDouble() * 0.4,
      size: 2.0 + _random.nextDouble() * 5.0,
      opacity: 0.1 + _random.nextDouble() * 0.25,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParticles);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(_particles),
      size: Size.infinite,
    );
  }
}

class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = Colors.white.withOpacity(particle.opacity);
      final dx = particle.x * size.width;
      final dy = particle.y * size.height;

      canvas.drawCircle(Offset(dx, dy), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
