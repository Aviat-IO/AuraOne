# Photo Scanning Improvements

## Problem

Photos taken with the device camera were not appearing in Today > Media or History > Media views because:

1. **Slow scanning interval**: Photos were scanned only every 30 minutes
2. **No immediate scanning**: Photo library changes didn't trigger immediate scans
3. **No scan on view**: Opening the Media tab didn't trigger a fresh scan

## Solution

### 1. Reduced Scan Interval (photo_service.dart)

**Before:**
```dart
Duration _scanInterval = const Duration(minutes: 30);
```

**After:**
```dart
Duration _scanInterval = const Duration(minutes: 5); // 6x faster
```

### 2. Immediate Scan on Photo Library Changes (photo_service.dart)

**Before:**
```dart
void _onPhotoLibraryChanged(MethodCall call) {
  _logger.info('Photo library changed: ${call.method}');
  // Trigger a rescan or update UI as needed
}
```

**After:**
```dart
void _onPhotoLibraryChanged(MethodCall call) {
  _logger.info('Photo library changed: ${call.method} - triggering immediate scan');
  // Trigger immediate scan when photos are added/changed
  Future.delayed(const Duration(seconds: 2), () {
    _performAutomaticScan();
  });
}
```

### 3. Scan on Today Tab View (preload_provider.dart)

Added automatic photo scanning when the Today tab is opened:

```dart
// Trigger photo scan for today to ensure latest photos are in database
Future.microtask(() async {
  try {
    final photoService = ref.read(photoServiceProvider);
    await photoService.scanAndIndexTodayPhotos();
    _logger.info('Triggered photo scan for today');
  } catch (e) {
    _logger.warning('Failed to trigger photo scan: $e');
  }
});
```

### 4. Scan on Media Tab View (media_gallery_widget.dart)

Added automatic photo scanning when the Media tab is opened:

```dart
// Trigger photo scan when media tab is viewed to ensure fresh data
useEffect(() {
  Future.microtask(() async {
    try {
      final photoService = ref.read(photoServiceProvider);
      await photoService.scanAndIndexPhotosForDate(date);
      debugPrint('Triggered photo scan for date $date in MediaGalleryWidget');
    } catch (e) {
      debugPrint('Failed to trigger photo scan: $e');
    }
  });
  return null;
}, [date]);
```

## Benefits

1. **Faster Discovery**: Photos appear within 5 minutes instead of 30 minutes
2. **Immediate Updates**: Taking a photo triggers a scan within 2 seconds
3. **Fresh Data**: Opening Media tab always scans for latest photos
4. **User-Friendly**: No manual refresh needed

## Timeline

| Event | Scan Trigger | Delay |
|-------|--------------|-------|
| Take photo with camera | Photo library change callback | 2 seconds |
| Open Today tab | Data warming provider | Immediate |
| Open Media tab | Media gallery useEffect | Immediate |
| Background | Periodic timer | Every 5 minutes |

## Testing

1. **Take a photo** with the device camera
2. Wait **2 seconds** for the photo library change callback
3. Navigate to **Today > Media**
4. Photo should appear immediately

If it doesn't:
- Check photo permissions (Settings > Permissions)
- Check logs for scan trigger messages
- Verify photo was actually saved to device library

## Code Hygiene

All changes maintain the **shared component architecture**:

- ✅ Both Today and History use `DailyEntryView`
- ✅ Changes to Media tab affect both screens equally
- ✅ No code duplication between screens

See `lib/widgets/SHARED_COMPONENTS.md` for architecture details.

## Performance Impact

- **Minimal**: Scanning is done asynchronously and doesn't block UI
- **Smart**: Multiple scan requests are deduplicated
- **Efficient**: Database updates are batched

## Related Files

- `lib/services/photo_service.dart` - Core photo scanning service
- `lib/providers/preload_provider.dart` - Today tab data warming
- `lib/widgets/daily_canvas/media_gallery_widget.dart` - Media tab UI
- `lib/widgets/daily_entry_view.dart` - Shared daily view component
