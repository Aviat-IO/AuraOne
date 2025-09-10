import 'package:flutter/material.dart';

/// A reusable help tooltip widget for providing contextual help information
/// Provides accessible help information with screen reader support
class HelpTooltip extends StatelessWidget {
  final String message;
  final String? detailedHelp;
  final Widget child;
  final IconData icon;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onHelpPressed;

  const HelpTooltip({
    super.key,
    required this.message,
    required this.child,
    this.detailedHelp,
    this.icon = Icons.help_outline,
    this.padding,
    this.onHelpPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(child: child),
        const SizedBox(width: 8),
        Semantics(
          label: 'Help information for ${message.toLowerCase()}',
          hint: 'Double tap for detailed help information',
          button: true,
          child: Tooltip(
            message: message,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: detailedHelp != null || onHelpPressed != null 
                    ? () => _showDetailedHelp(context) 
                    : null,
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(4),
                  child: Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDetailedHelp(BuildContext context) {
    if (onHelpPressed != null) {
      onHelpPressed!();
      return;
    }
    
    if (detailedHelp != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Help'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(detailedHelp!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
  }
}

/// A help info button that can be placed next to any widget
/// Provides consistent help button styling and accessibility
class HelpInfoButton extends StatelessWidget {
  final String message;
  final String? detailedHelp;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  const HelpInfoButton({
    super.key,
    required this.message,
    this.detailedHelp,
    this.onPressed,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: 'Help: $message',
      hint: 'Double tap to show help information',
      button: true,
      child: Tooltip(
        message: message,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(size / 2),
            onTap: onPressed ?? () => _showDetailedHelp(context),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.info_outline,
                size: size,
                color: color ?? theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailedHelp(BuildContext context) {
    if (detailedHelp != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Help'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(detailedHelp!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
  }
}

/// A section header with optional help information
/// Provides accessible section headings with contextual help
class HelpSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? helpText;
  final IconData? icon;
  final VoidCallback? onHelpPressed;

  const HelpSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.helpText,
    this.icon,
    this.onHelpPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (helpText != null || onHelpPressed != null)
                HelpInfoButton(
                  message: helpText ?? 'Help for $title',
                  detailedHelp: helpText,
                  onPressed: onHelpPressed,
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}