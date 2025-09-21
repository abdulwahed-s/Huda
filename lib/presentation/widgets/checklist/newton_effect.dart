import 'package:flutter/material.dart';
import 'package:newton_particles/newton_particles.dart';
import 'package:newton_particles/newton_particles.dart' as newton;

class NewtonEffect extends StatelessWidget {
  const NewtonEffect({super.key});

  @override
  Widget build(BuildContext context) {
    return Newton(
      effectConfigurations: [
        _createSparkleEffect(),
        _createPulseEffect(),
      ],
    );
  }

  RelativisticEffectConfiguration _createSparkleEffect() {
    return RelativisticEffectConfiguration(
      gravity: newton.Gravity.earthGravity,
      minAngle: -120, // Spread upward from bottom
      maxAngle: -60,
      minFadeOutThreshold: 0.6,
      maxFadeOutThreshold: 0.8,
      maxParticleLifespan: const Duration(seconds: 3),
      emitDuration: const Duration(milliseconds: 1500),
      minEndScale: 3,
      maxEndScale: 8,
      minVelocity: const newton.Velocity(8),
      maxVelocity: const newton.Velocity(20),
      origin: const Offset(
          0.5, 1.1), // Start from bottom center (slightly below screen)
      solidEdges: newton.SolidEdges.none,
      particleCount: 60,
      particlesPerEmit: 8,
      particleConfiguration: const newton.ParticleConfiguration(
        shape: newton.CircleShape(),
        size: Size(6, 6),
        color: newton.LinearInterpolationParticleColor(
          colors: [
            Colors.yellow,
            Colors.orange,
            Colors.red,
            Colors.pink,
            Colors.purple,
            Colors.white,
          ],
        ),
      ),
    );
  }

  RelativisticEffectConfiguration _createPulseEffect() {
    return RelativisticEffectConfiguration(
      configurationOverrider: (effect) {
        final particlesPerEmit = effect.effectConfiguration.particlesPerEmit;
        final angle = 360 /
            particlesPerEmit *
            (effect.activeParticles.length % particlesPerEmit);
        return effect.effectConfiguration
            .copyWith(maxAngle: angle, minAngle: angle);
      },
      gravity: Gravity.zero,
      emitDuration: const Duration(seconds: 1),
      maxEndScale: 1,
      maxFadeOutThreshold: .8,
      maxParticleLifespan: const Duration(seconds: 10),
      maxVelocity: const newton.Velocity(.6),
      minEndScale: 1,
      onlyInteractWithEdges: true,
      minParticleLifespan: const Duration(seconds: 10),
      minVelocity: const newton.Velocity(.6),
      minFadeOutThreshold: .8,
      particleConfiguration: const ParticleConfiguration(
        shape: CircleShape(),
        size: Size(6, 6),
        color: newton.LinearInterpolationParticleColor(
          colors: [
            Colors.yellow,
            Colors.orange,
            Colors.red,
            Colors.pink,
            Colors.purple,
            Colors.white,
          ],
        ),
      ),
      particlesPerEmit: 30,
    );
  }
}
