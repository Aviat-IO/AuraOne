import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/permission_request_dialog.dart';

// Provider for permission manager
final permissionManagerProvider = Provider((ref) => PermissionManager());

// Provider for tracking permission states
final permissionStatesProvider = StateNotifierProvider<PermissionStatesNotifier, Map<Permission, PermissionStatus>>((ref) {
  return PermissionStatesNotifier();
});

class PermissionStatesNotifier extends StateNotifier<Map<Permission, PermissionStatus>> {
  PermissionStatesNotifier() : super({});

  void updateStatus(Permission permission, PermissionStatus status) {
    state = {...state, permission: status};
  }

  Future<void> checkAllPermissions() async {
    final permissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.photos,
      Permission.camera,
      Permission.contacts,
      Permission.calendar,
      Permission.microphone,
      Permission.notification,
    ];

    final Map<Permission, PermissionStatus> statuses = {};
    for (final permission in permissions) {
      statuses[permission] = await permission.status;
    }
    state = statuses;
  }
}

class PermissionManager {
  static const String _permissionRequestedPrefix = 'permission_requested_';
  static const String _permissionDeniedCountPrefix = 'permission_denied_count_';

  // Permission configurations with contextual explanations
  final Map<Permission, PermissionConfig> _configs = {
    Permission.location: PermissionConfig(
      permission: Permission.location,
      title: 'Location Access',
      explanation: 'Aura One needs location access to track your aura in different places and provide location-based insights.',
      icon: Icons.location_on,
      benefits: [
        'Track aura patterns in different locations',
        'Get location-based wellness insights',
        'Discover how environments affect your energy',
      ],
      deniedMessage: 'Without location access, Aura One cannot provide location-based aura insights.',
      alternativeAction: 'You can still manually log your locations in the app.',
    ),
    
    Permission.locationAlways: PermissionConfig(
      permission: Permission.locationAlways,
      title: 'Background Location',
      explanation: 'Allow Aura One to track your aura patterns even when the app is in the background for continuous insights.',
      icon: Icons.my_location,
      benefits: [
        'Continuous aura tracking throughout your day',
        'Automatic location-based pattern detection',
        'Better understanding of environmental influences',
      ],
      deniedMessage: 'Background location helps provide comprehensive aura insights.',
      alternativeAction: 'The app will only track when open without this permission.',
    ),
    
    Permission.photos: PermissionConfig(
      permission: Permission.photos,
      title: 'Photo Library Access',
      explanation: 'Aura One needs access to your photos to analyze and share aura visualizations.',
      icon: Icons.photo_library,
      benefits: [
        'Save aura visualizations to your gallery',
        'Share aura photos with friends',
        'Create personalized aura profiles',
      ],
      deniedMessage: 'Without photo access, you cannot save or share aura visualizations.',
      alternativeAction: 'You can still view visualizations within the app.',
    ),
    
    Permission.camera: PermissionConfig(
      permission: Permission.camera,
      title: 'Camera Access',
      explanation: 'Use your camera to capture aura photos and scan energy fields.',
      icon: Icons.camera_alt,
      benefits: [
        'Capture real-time aura photos',
        'Scan and analyze energy fields',
        'Create visual aura records',
      ],
      deniedMessage: 'Camera access is needed for aura photography features.',
      alternativeAction: 'You can import existing photos instead.',
    ),
    
    Permission.contacts: PermissionConfig(
      permission: Permission.contacts,
      title: 'Contacts Access',
      explanation: 'Connect with friends to share aura insights and build your spiritual network.',
      icon: Icons.contacts,
      benefits: [
        'Find friends using Aura One',
        'Share aura readings with contacts',
        'Build your spiritual community',
      ],
      deniedMessage: 'Without contacts access, you cannot easily connect with friends.',
      alternativeAction: 'You can manually search for friends by username.',
    ),
    
    Permission.calendar: PermissionConfig(
      permission: Permission.calendar,
      title: 'Calendar Access',
      explanation: 'Sync your aura patterns with calendar events to understand how activities affect your energy.',
      icon: Icons.calendar_today,
      benefits: [
        'Correlate aura changes with events',
        'Schedule aura-friendly activities',
        'Track energy patterns over time',
      ],
      deniedMessage: 'Calendar access helps understand how events affect your aura.',
      alternativeAction: 'You can manually log important events.',
    ),
    
    Permission.microphone: PermissionConfig(
      permission: Permission.microphone,
      title: 'Microphone Access',
      explanation: 'Analyze voice patterns to detect emotional energy and aura fluctuations.',
      icon: Icons.mic,
      benefits: [
        'Voice-based aura analysis',
        'Emotional energy detection',
        'Sound healing features',
      ],
      deniedMessage: 'Microphone access enables voice-based aura features.',
      alternativeAction: 'You can use other input methods for aura tracking.',
    ),
    
    Permission.notification: PermissionConfig(
      permission: Permission.notification,
      title: 'Notification Access',
      explanation: 'Receive timely aura insights and wellness reminders throughout your day.',
      icon: Icons.notifications,
      benefits: [
        'Daily aura updates and insights',
        'Meditation and wellness reminders',
        'Energy shift alerts',
      ],
      deniedMessage: 'Without notifications, you\'ll miss important aura updates.',
      alternativeAction: 'Check the app regularly for updates.',
    ),
  };

  Future<bool> hasRequestedBefore(Permission permission) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_permissionRequestedPrefix${permission.value}') ?? false;
  }

  Future<void> markAsRequested(Permission permission) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_permissionRequestedPrefix${permission.value}', true);
  }

  Future<int> getDeniedCount(Permission permission) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_permissionDeniedCountPrefix${permission.value}') ?? 0;
  }

  Future<void> incrementDeniedCount(Permission permission) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getDeniedCount(permission);
    await prefs.setInt('$_permissionDeniedCountPrefix${permission.value}', current + 1);
  }

  Future<PermissionStatus> requestPermission(
    BuildContext context,
    Permission permission, {
    bool showEducationalUI = true,
    bool forceRequest = false,
  }) async {
    final config = _configs[permission];
    if (config == null) {
      // Fallback for permissions without config
      return await permission.request();
    }

    // Check current status
    PermissionStatus status = await permission.status;
    
    // If already granted, return
    if (status.isGranted || status.isLimited) {
      return status;
    }
    
    // If permanently denied, show settings dialog
    if (status.isPermanentlyDenied) {
      if (showEducationalUI && context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => PermissionDeniedDialog(
            title: 'Permission Required',
            message: config.deniedMessage ?? 'This permission is required for the feature to work.',
            alternativeAction: config.alternativeAction,
            onSettingsPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
          ),
        );
      }
      return status;
    }
    
    // Show educational UI if needed
    bool shouldRequest = forceRequest;
    
    if (showEducationalUI && !forceRequest) {
      final hasRequested = await hasRequestedBefore(permission);
      final deniedCount = await getDeniedCount(permission);
      
      // Show educational UI if first time or denied less than 3 times
      if (!hasRequested || deniedCount < 3) {
        if (context.mounted) {
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => PermissionRequestDialog(
              permission: permission,
              title: config.title,
              explanation: config.explanation,
              icon: config.icon,
              benefits: config.benefits,
            ),
          );
          
          shouldRequest = result ?? false;
        }
      } else {
        shouldRequest = true;
      }
    }
    
    // Request permission if user agreed
    if (shouldRequest) {
      await markAsRequested(permission);
      status = await permission.request();
      
      if (status.isDenied) {
        await incrementDeniedCount(permission);
        
        // Show denied dialog if educational UI was shown
        if (showEducationalUI && context.mounted) {
          final deniedCount = await getDeniedCount(permission);
          if (deniedCount >= 2) {
            await showDialog(
              context: context,
              builder: (context) => PermissionDeniedDialog(
                title: 'Permission Denied',
                message: config.deniedMessage ?? 'This feature requires the permission to work properly.',
                alternativeAction: config.alternativeAction,
                onSettingsPressed: deniedCount >= 3 ? () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                } : null,
              ),
            );
          }
        }
      }
    }
    
    return status;
  }

  Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    BuildContext context,
    List<Permission> permissions, {
    bool showEducationalUI = true,
  }) async {
    final Map<Permission, PermissionStatus> results = {};
    
    for (final permission in permissions) {
      if (context.mounted) {
        results[permission] = await requestPermission(
          context,
          permission,
          showEducationalUI: showEducationalUI,
        );
      }
    }
    
    return results;
  }

  PermissionConfig? getConfig(Permission permission) {
    return _configs[permission];
  }
}

class PermissionConfig {
  final Permission permission;
  final String title;
  final String explanation;
  final IconData icon;
  final List<String> benefits;
  final String? deniedMessage;
  final String? alternativeAction;

  const PermissionConfig({
    required this.permission,
    required this.title,
    required this.explanation,
    required this.icon,
    required this.benefits,
    this.deniedMessage,
    this.alternativeAction,
  });
}