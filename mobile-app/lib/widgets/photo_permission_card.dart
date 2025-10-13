import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/photo_service.dart';
import '../providers/photo_service_provider.dart';

class PhotoPermissionCard extends ConsumerWidget {
  const PhotoPermissionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissionAsync = ref.watch(photoPermissionStateProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: permissionAsync.when(
          data: (permission) => _buildPermissionContent(context, ref, permission),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_library,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Photo Library',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Error accessing photo library: $error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionContent(BuildContext context, WidgetRef ref, PermissionState permission) {
    final theme = Theme.of(context);
    final service = ref.read(photoServiceProvider);

    final hasFullAccess = permission.isAuth;
    final hasLimitedAccess = permission.hasAccess && !permission.isAuth;
    final noAccess = !permission.hasAccess;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library,
              color: hasFullAccess
                ? Colors.green
                : hasLimitedAccess
                  ? Colors.orange
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              'Photo Library Access',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (hasFullAccess
              ? Colors.green
              : hasLimitedAccess
                ? Colors.orange
                : Colors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (hasFullAccess
                ? Colors.green
                : hasLimitedAccess
                  ? Colors.orange
                  : Colors.grey).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: hasFullAccess
                    ? Colors.green
                    : hasLimitedAccess
                      ? Colors.orange
                      : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasFullAccess
                    ? 'Full Access Granted'
                    : hasLimitedAccess
                      ? 'Limited Access'
                      : 'Access Denied',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasFullAccess
                      ? Colors.green
                      : hasLimitedAccess
                        ? Colors.orange
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Description
        Text(
          hasFullAccess
            ? 'Aura One can discover photos and videos from your day to enrich your journal entries.'
            : hasLimitedAccess
              ? 'You\'ve granted limited access. Tap "Select More Photos" to choose additional photos.'
              : 'Grant access to let Aura One discover photos from your day.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        // Action buttons
        if (noAccess) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await service.requestPermissions();
                    ref.invalidate(photoPermissionStateProvider);
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Grant Access'),
                ),
              ),
            ],
          ),
        ] else if (hasLimitedAccess) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await service.presentLimitedSelection();
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Select More Photos'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await service.openSettings();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Full access - show photo count
          FutureBuilder<List<AssetEntity>>(
            future: ref.watch(todayPhotosProvider.future),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }

              final photoCount = snapshot.data?.length ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      photoCount > 0
                        ? 'Found $photoCount photos from today'
                        : 'No photos from today yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
