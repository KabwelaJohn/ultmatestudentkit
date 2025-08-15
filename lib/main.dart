import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

void main() {
  runApp(const ParticlePlaygroundApp());
}

class ParticlePlaygroundApp extends StatelessWidget {
  const ParticlePlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Particle Playground',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.purple,
          secondary: Colors.cyan,
        ),
      ),
      home: const ParticlePlayground(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Particle {
  double x, y;
  double vx, vy;
  double life;
  double maxLife;
  Color color;
  double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
  });

  void update() {
    x += vx;
    y += vy;
    life -= 1;

    // Add some gravity
    vy += 0.1;

    // Add some drag
    vx *= 0.99;
    vy *= 0.99;
  }

  bool get isDead => life <= 0;

  double get alpha => (life / maxLife).clamp(0.0, 1.0);
}

class ParticleSystem {
  List<Particle> particles = [];
  final math.Random random = math.Random();

  void addParticle(double x, double y, Color baseColor) {
    final angle = random.nextDouble() * 2 * math.pi;
    final speed = random.nextDouble() * 8 + 2;
    final life = random.nextDouble() * 60 + 30;

    particles.add(
      Particle(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - random.nextDouble() * 5,
        life: life,
        maxLife: life,
        color: Color.lerp(baseColor, Colors.white, random.nextDouble() * 0.3)!,
        size: random.nextDouble() * 6 + 2,
      ),
    );
  }

  void update() {
    for (var particle in particles) {
      particle.update();
    }
    particles.removeWhere((particle) => particle.isDead);
  }
}

class ParticlePlayground extends StatefulWidget {
  const ParticlePlayground({super.key});

  @override
  State<ParticlePlayground> createState() => _ParticlePlaygroundState();
}

class _ParticlePlaygroundState extends State<ParticlePlayground>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final ParticleSystem _particleSystem = ParticleSystem();
  Color _currentColor = Colors.purple;
  bool _isEmitting = false;
  double _emissionRate = 5;
  int _frameCount = 0;

  final List<Color> _colorPalette = [
    Colors.purple,
    Colors.cyan,
    Colors.pink,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.blue,
    Colors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 16), // ~60 FPS
      vsync: this,
    )..repeat();

    _animationController.addListener(() {
      setState(() {
        _particleSystem.update();
        _frameCount++;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isEmitting) {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final localPosition = box.globalToLocal(details.globalPosition);

      // Add multiple particles based on emission rate
      for (int i = 0; i < _emissionRate.round(); i++) {
        _particleSystem.addParticle(
          localPosition.dx + (math.Random().nextDouble() - 0.5) * 20,
          localPosition.dy + (math.Random().nextDouble() - 0.5) * 20,
          _currentColor,
        );
      }
    }
  }

  void _handleTap(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    // Create explosion effect
    for (int i = 0; i < 20; i++) {
      _particleSystem.addParticle(
        localPosition.dx,
        localPosition.dy,
        _currentColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Particle Canvas
          GestureDetector(
            onPanUpdate: _handlePanUpdate,
            onTapDown: _handleTap,
            child: CustomPaint(
              painter: ParticlePainter(_particleSystem.particles),
              size: Size.infinite,
            ),
          ),

          // Control Panel
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.black.withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Particle Playground',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: _currentColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'By Kabwela John @Paraddroid',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Color Palette
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _colorPalette.map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => _currentColor = color),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: _currentColor == color
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Emission Rate Slider
                    Row(
                      children: [
                        const Text('Flow: '),
                        Expanded(
                          child: Slider(
                            value: _emissionRate,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            activeColor: _currentColor,
                            onChanged: (value) {
                              setState(() => _emissionRate = value);
                            },
                          ),
                        ),
                        Text(_emissionRate.round().toString()),
                      ],
                    ),

                    // Toggle Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Continuous Mode:'),
                        Switch(
                          value: _isEmitting,
                          activeColor: _currentColor,
                          onChanged: (value) {
                            setState(() => _isEmitting = value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.black.withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '✨ Instructions ✨',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _currentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Tap anywhere for explosions\n'
                      '• Drag to paint with particles\n'
                      '• Use continuous mode for trails\n'
                      '• Change colors and flow rate',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Particles: ${_particleSystem.particles.length}',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      paint.color = particle.color.withOpacity(particle.alpha);

      // Create a radial gradient for each particle
      final gradient = ui.Gradient.radial(
        Offset(particle.x, particle.y),
        particle.size,
        [
          particle.color.withOpacity(particle.alpha),
          particle.color.withOpacity(0),
        ],
        [0.0, 1.0],
      );

      paint.shader = gradient;

      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.particles != particles;
  }
}
