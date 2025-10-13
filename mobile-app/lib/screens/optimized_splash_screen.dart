import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../theme/colors.dart';
import '../services/background_init_service.dart';

/// Optimized splash screen with initialization progress
class OptimizedSplashScreen extends HookConsumerWidget {
  const OptimizedSplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Use stream to listen to initialization progress
    final progressStream = useMemoized(() => BackgroundInitService().progressStream);
    final progressSnapshot = useStream(progressStream);

    final progress = progressSnapshot.data?.progress ?? 0.0;
    final currentStep = progressSnapshot.data?.step ?? 'Initializing...';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
              ? AuraColors.lightBackgroundGradient
              : AuraColors.darkBackgroundGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Logo
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: _buildLogo(isLight),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // App Title
                  FadeTransition(
                    opacity: AlwaysStoppedAnimation(progress > 0.2 ? 1.0 : 0.0),
                    child: Text(
                      'Aura One',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  FadeTransition(
                    opacity: AlwaysStoppedAnimation(progress > 0.3 ? 1.0 : 0.0),
                    child: Text(
                      'Your Personal Wellness Journey',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  FadeTransition(
                    opacity: AlwaysStoppedAnimation(progress > 0.4 ? 1.0 : 0.0),
                    child: Text(
                      'Powered by Nostr • Location-Aware • Private',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Progress Indicator with percentage
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        // Linear progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Progress text and percentage
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currentStep,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Loading tips (rotate through different tips)
                  _LoadingTips(progress: progress),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isLight) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
            ? AuraColors.lightLogoGradient
            : AuraColors.darkLogoGradient,
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
              ? AuraColors.lightPrimary.withValues(alpha: 0.2)
              : AuraColors.darkPrimary.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated outer ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, rotation, child) {
              return Transform.rotate(
                angle: rotation * 2 * 3.14159,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          ClipOval(
            child: Container(
              width: 70,
              height: 70,
              color: Colors.white.withValues(alpha: 0.15),
              child: Image.asset(
                'assets/icons/aura_one_logo.png',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to show rotating loading tips
class _LoadingTips extends HookWidget {
  final double progress;

  const _LoadingTips({required this.progress});

  @override
  Widget build(BuildContext context) {
    final tips = [
      'Preparing your wellness journey...',
      'Setting up secure storage...',
      'Initializing AI assistants...',
      'Configuring privacy settings...',
      'Almost ready to begin...',
    ];

    final tipIndex = ((progress * tips.length).floor()).clamp(0, tips.length - 1);
    final currentTip = tips[tipIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        currentTip,
        key: ValueKey(currentTip),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}