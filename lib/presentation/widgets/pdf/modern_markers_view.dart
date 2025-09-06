import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/pdf/marker.dart';

class ModernMarkersView extends StatefulWidget {
  const ModernMarkersView({
    required this.markers,
    super.key,
    this.onTap,
    this.onDeleteTap,
  });

  final List<Marker> markers;
  final void Function(Marker marker)? onTap;
  final void Function(Marker marker)? onDeleteTap;

  @override
  State<ModernMarkersView> createState() => _ModernMarkersViewState();
}

class _ModernMarkersViewState extends State<ModernMarkersView> {
  late List<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = widget.markers;
  }

  @override
  void didUpdateWidget(ModernMarkersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.markers != oldWidget.markers) {
      setState(() {
        _markers = widget.markers;
      });
    }
  }

  void _deleteMarker(Marker marker) {
    setState(() {
      _markers = _markers.where((m) => m != marker).toList();
    });
    widget.onDeleteTap?.call(marker);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_markers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noMarkersYet,
              style: TextStyle(
                fontSize: 16.sp,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final marker = _markers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: marker.color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Material(
            color: marker.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onTap?.call(marker),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: marker.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .pageLabel(marker.range.pageNumber.toString()),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            marker.range.text,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      onPressed: () => _deleteMarker(marker),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      itemCount: _markers.length,
    );
  }
}
