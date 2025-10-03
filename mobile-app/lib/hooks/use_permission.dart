import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_manager.dart';

/// Hook for managing permission requests with just-in-time UI
class PermissionState {
  final PermissionStatus status;
  final bool isRequesting;
  final Future<PermissionStatus> Function() request;
  final Future<void> Function() openSettings;

  const PermissionState({
    required this.status,
    required this.isRequesting,
    required this.request,
    required this.openSettings,
  });

  bool get isGranted => status.isGranted || status.isLimited;
  bool get isDenied => status.isDenied;
  bool get isPermanentlyDenied => status.isPermanentlyDenied;
  bool get isRestricted => status.isRestricted;
}

PermissionState usePermission(
  Permission permission,
  WidgetRef ref, {
  bool autoRequest = false,
  bool showEducationalUI = true,
}) {
  final context = useContext();
  final status = useState<PermissionStatus>(PermissionStatus.denied);
  final isRequesting = useState(false);
  final hasAutoRequested = useState(false);

  // Request function
  Future<PermissionStatus> request() async {
    if (isRequesting.value) return status.value;

    isRequesting.value = true;

    try {
      final manager = ref.read(permissionManagerProvider);
      final newStatus = await manager.requestPermission(
        context,
        permission,
        showEducationalUI: showEducationalUI,
      );

      status.value = newStatus;

      // Update global state
      ref.read(permissionStatesProvider.notifier).updateStatus(permission, newStatus);

      return newStatus;
    } finally {
      isRequesting.value = false;
    }
  }

  // Open settings function
  Future<void> openSettingsFunc() async {
    await openAppSettings();
    // Re-check permission when returning
    final newStatus = await permission.status;
    status.value = newStatus;
    ref.read(permissionStatesProvider.notifier).updateStatus(permission, newStatus);
  }

  // Check initial permission status
  useEffect(() {
    Future<void> checkStatus() async {
      final currentStatus = await permission.status;
      status.value = currentStatus;

      // Update global state
      ref.read(permissionStatesProvider.notifier).updateStatus(permission, currentStatus);

      // Auto-request if enabled and not already granted
      if (autoRequest && !hasAutoRequested.value && !currentStatus.isGranted) {
        hasAutoRequested.value = true;
        await request();
      }
    }

    checkStatus();

    return null;
  }, [permission]);

  return PermissionState(
    status: status.value,
    isRequesting: isRequesting.value,
    request: request,
    openSettings: openSettingsFunc,
  );
}

/// Hook for multiple permissions
class MultiplePermissionsState {
  final Map<Permission, PermissionStatus> statuses;
  final bool isRequesting;
  final Future<Map<Permission, PermissionStatus>> Function() requestAll;
  final Future<PermissionStatus> Function(Permission) requestSingle;
  final Future<void> Function() openSettings;

  const MultiplePermissionsState({
    required this.statuses,
    required this.isRequesting,
    required this.requestAll,
    required this.requestSingle,
    required this.openSettings,
  });

  bool get allGranted => statuses.values.every((s) => s.isGranted || s.isLimited);
  bool get anyDenied => statuses.values.any((s) => s.isDenied);
  bool get anyPermanentlyDenied => statuses.values.any((s) => s.isPermanentlyDenied);
}

MultiplePermissionsState useMultiplePermissions(
  List<Permission> permissions,
  WidgetRef ref, {
  bool autoRequest = false,
  bool showEducationalUI = true,
}) {
  final context = useContext();
  final statuses = useState<Map<Permission, PermissionStatus>>({});
  final isRequesting = useState(false);
  final hasAutoRequested = useState(false);

  // Request all permissions
  Future<Map<Permission, PermissionStatus>> requestAll() async {
    if (isRequesting.value) return statuses.value;

    isRequesting.value = true;

    try {
      final manager = ref.read(permissionManagerProvider);
      final newStatuses = await manager.requestMultiplePermissions(
        context,
        permissions,
        showEducationalUI: showEducationalUI,
      );

      statuses.value = newStatuses;

      // Update global state
      final notifier = ref.read(permissionStatesProvider.notifier);
      for (final entry in newStatuses.entries) {
        notifier.updateStatus(entry.key, entry.value);
      }

      return newStatuses;
    } finally {
      isRequesting.value = false;
    }
  }

  // Request single permission
  Future<PermissionStatus> requestSingle(Permission permission) async {
    if (!permissions.contains(permission)) {
      throw ArgumentError('Permission not in the list of managed permissions');
    }

    if (isRequesting.value) return statuses.value[permission] ?? PermissionStatus.denied;

    isRequesting.value = true;

    try {
      final manager = ref.read(permissionManagerProvider);
      final newStatus = await manager.requestPermission(
        context,
        permission,
        showEducationalUI: showEducationalUI,
      );

      statuses.value = {...statuses.value, permission: newStatus};

      // Update global state
      ref.read(permissionStatesProvider.notifier).updateStatus(permission, newStatus);

      return newStatus;
    } finally {
      isRequesting.value = false;
    }
  }

  // Open settings function
  Future<void> openSettingsFunc() async {
    await openAppSettings();
    // Re-check all permissions when returning
    final Map<Permission, PermissionStatus> newStatuses = {};

    for (final permission in permissions) {
      newStatuses[permission] = await permission.status;
    }

    statuses.value = newStatuses;

    // Update global state
    final notifier = ref.read(permissionStatesProvider.notifier);
    for (final entry in newStatuses.entries) {
      notifier.updateStatus(entry.key, entry.value);
    }
  }

  // Check initial permission statuses
  useEffect(() {
    Future<void> checkStatuses() async {
      final Map<Permission, PermissionStatus> currentStatuses = {};

      for (final permission in permissions) {
        currentStatuses[permission] = await permission.status;
      }

      statuses.value = currentStatuses;

      // Update global state
      final notifier = ref.read(permissionStatesProvider.notifier);
      for (final entry in currentStatuses.entries) {
        notifier.updateStatus(entry.key, entry.value);
      }

      // Auto-request if enabled and not all granted
      if (autoRequest && !hasAutoRequested.value) {
        hasAutoRequested.value = true;
        final notGranted = currentStatuses.entries
            .where((e) => !e.value.isGranted && !e.value.isLimited)
            .map((e) => e.key)
            .toList();

        if (notGranted.isNotEmpty) {
          await requestAll();
        }
      }
    }

    checkStatuses();

    return null;
  }, permissions);

  return MultiplePermissionsState(
    statuses: statuses.value,
    isRequesting: isRequesting.value,
    requestAll: requestAll,
    requestSingle: requestSingle,
    openSettings: openSettingsFunc,
  );
}
