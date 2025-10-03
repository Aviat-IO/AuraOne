import 'package:flutter/material.dart';

/// Optimized list view that uses lazy loading and efficient rendering
/// to prevent frame drops and improve performance
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double cacheExtent;
  final int itemsPerBatch;
  final bool enableFrameScheduling;
  final Widget? loadingIndicator;
  final Widget? emptyState;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.cacheExtent = 250.0, // Pre-render items slightly outside viewport
    this.itemsPerBatch = 20, // Number of items to render per frame
    this.enableFrameScheduling = true,
    this.loadingIndicator,
    this.emptyState,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  late ScrollController _scrollController;
  final Set<int> _renderedIndices = {};
  bool _isScrolling = false;
  DateTime? _lastScrollTime;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    // Detect scrolling state for optimization
    if (!_isScrolling) {
      setState(() {
        _isScrolling = true;
        _lastScrollTime = DateTime.now();
      });

      // Schedule state update after scrolling stops
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_lastScrollTime != null &&
            DateTime.now().difference(_lastScrollTime!).inMilliseconds >= 150) {
          if (mounted) {
            setState(() {
              _isScrolling = false;
            });
          }
        }
      });
    } else {
      _lastScrollTime = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyState ??
        const Center(
          child: Text('No items to display'),
        );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      cacheExtent: widget.cacheExtent,
      // Use addAutomaticKeepAlives and addRepaintBoundaries for better performance
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        // Skip complex rendering during fast scrolling
        if (_isScrolling && !_renderedIndices.contains(index)) {
          _renderedIndices.add(index);

          // Show placeholder during scrolling for unrendered items
          return _buildPlaceholder(index);
        }

        // Mark as rendered
        _renderedIndices.add(index);

        // Wrap each item in RepaintBoundary for performance
        return RepaintBoundary(
          child: widget.enableFrameScheduling
              ? _FrameScheduledItem<T>(
                  item: widget.items[index],
                  index: index,
                  itemBuilder: widget.itemBuilder,
                )
              : widget.itemBuilder(context, widget.items[index], index),
        );
      },
    );
  }

  Widget _buildPlaceholder(int index) {
    return widget.loadingIndicator ??
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
  }
}

/// Widget that schedules rendering on the next frame to prevent jank
class _FrameScheduledItem<T> extends StatefulWidget {
  final T item;
  final int index;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  const _FrameScheduledItem({
    required this.item,
    required this.index,
    required this.itemBuilder,
  });

  @override
  State<_FrameScheduledItem<T>> createState() => _FrameScheduledItemState<T>();
}

class _FrameScheduledItemState<T> extends State<_FrameScheduledItem<T>> {
  bool _isBuilt = false;

  @override
  void initState() {
    super.initState();
    // Schedule build on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isBuilt = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBuilt) {
      // Return placeholder while waiting for next frame
      return Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        child: const LinearProgressIndicator(),
      );
    }

    return widget.itemBuilder(context, widget.item, widget.index);
  }
}

/// Extension to add performance helpers
extension PerformanceHelpers on BuildContext {
  /// Schedule a callback to run on the next frame
  void scheduleFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }

  /// Check if we should defer heavy operations
  bool get shouldDeferOperations {
    final scrollable = Scrollable.maybeOf(this);
    if (scrollable == null) return false;

    final position = scrollable.position;
    // Defer if scrolling fast
    return position.activity?.velocity != null &&
           position.activity!.velocity.abs() > 1000;
  }
}