import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/location.dart';
import '../../core/providers.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';
import '../shell/home_shell.dart';
import 'heat_layer.dart';

/// Visible area snapped to a 0.25° grid so small pans reuse the cached query.
typedef MapQuery = ({int days, int south, int west, int north, int east});

const _gridPerDegree = 4;

final mapReportsProvider = FutureProvider.autoDispose.family<List<Report>, MapQuery>((ref, q) {
  return ref
      .watch(repositoryProvider)
      .mapReports(
        southWest: LatLng(q.south / _gridPerDegree, q.west / _gridPerDegree),
        northEast: LatLng(q.north / _gridPerDegree, q.east / _gridPerDegree),
        since: Duration(days: q.days),
      );
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _markerZoom = 16;
  final _map = MapController();
  int _days = 7;
  MapQuery? _query;
  int _zoom = 13;
  List<Report> _reports = const [];
  List<HeatCluster> _clusters = const [];
  (int, List<Report>)? _clusteredFor;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _updateQuery(MapCamera camera) {
    final b = camera.visibleBounds;
    final q = (
      days: _days,
      south: (b.south * _gridPerDegree).floor() - 1,
      west: (b.west * _gridPerDegree).floor() - 1,
      north: (b.north * _gridPerDegree).ceil() + 1,
      east: (b.east * _gridPerDegree).ceil() + 1,
    );
    final zoom = camera.zoom.floor();
    if (q != _query || zoom != _zoom) {
      setState(() {
        _query = q;
        _zoom = zoom;
      });
    }
  }

  List<HeatCluster> _clustersFor(MapCamera camera) {
    final key = _clusteredFor;
    if (key == null || key.$1 != _zoom || !identical(key.$2, _reports)) {
      _clusters = clusterReports(_reports, camera, _zoom);
      _clusteredFor = (_zoom, _reports);
    }
    return _clusters;
  }

  void _onTap(LatLng point) {
    if (_zoom >= _markerZoom || _clusters.isEmpty) return;
    final camera = _map.camera;
    final tap = camera.getOffsetFromOrigin(point);
    final scale = camera.getZoomScale(camera.zoom, _zoom.toDouble()).clamp(0.6, 1.6);
    HeatCluster? best;
    var bestDistance = double.infinity;
    for (final c in _clusters) {
      final d = (camera.getOffsetFromOrigin(c.center) - tap).distance;
      if (d < HeatLayer.radiusFor(c.reports.length, scale) * 0.8 && d < bestDistance) {
        best = c;
        bestDistance = d;
      }
    }
    if (best != null) unawaited(_showCluster(best));
  }

  Future<void> _showCluster(HeatCluster cluster) => showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ClusterSheet(reports: [...cluster.reports]..sort((a, b) => b.createdAt.compareTo(a.createdAt))),
  );

  Future<void> _locate() async {
    ref.invalidate(approximateFixProvider);
    final fix = await ref.read(approximateFixProvider.future);
    if (fix != null && mounted) _map.move(fix.position, math.max(_map.camera.zoom, 14));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final catalog = ref.watch(catalogProvider);
    final start = ref.watch(approximateFixProvider).value?.position ?? LocationService.dhaka;
    final query = _query;
    if (query != null) {
      final async = ref.watch(mapReportsProvider(query));
      // Keep showing the previous points while the next area loads.
      if (async.value != null && !identical(async.value, _reports)) _reports = async.value!;
    }
    final loading = query != null && ref.watch(mapReportsProvider(query)).isLoading;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: start,
              initialZoom: 13,
              minZoom: 6,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onMapReady: () => _updateQuery(_map.camera),
              onPositionChanged: (camera, _) => _updateQuery(camera),
              onTap: (_, point) => _onTap(point),
            ),
            children: [
              TileLayer(urlTemplate: AppConfig.tileUrl, userAgentPackageName: 'bd.sajag.app'),
              if (_zoom >= _markerZoom)
                MarkerLayer(
                  markers: [
                    for (final r in _reports)
                      Marker(
                        point: LatLng(r.lat, r.lng),
                        width: 44,
                        height: 44,
                        child: _ReportPin(report: r, category: catalog.category(r.categoryId)),
                      ),
                  ],
                )
              else
                Builder(
                  builder: (context) => HeatLayer(
                    clusters: _clustersFor(MapCamera.of(context)),
                    clusterZoom: _zoom,
                    showCounts: _zoom >= 12,
                  ),
                ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topRight,
                child: _RangeMenu(
                  days: _days,
                  onChanged: (d) {
                    setState(() => _days = d);
                    _updateQuery(_map.camera);
                  },
                ),
              ),
            ),
          ),
          if (loading) const Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: LinearProgressIndicator())),
          // Tile attribution (required by OpenStreetMap), kept visible above the floating tab bar.
          Positioned(
            right: 12,
            bottom: navClearance(context) + 64,
            child: GestureDetector(
              onTap: () =>
                  launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'), mode: LaunchMode.externalApplication),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('© ${AppConfig.tileAttribution}', style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: navClearance(context),
            child: HeatLegend(few: l.mapLegendFew, many: l.mapLegendMany),
          ),
          Positioned(
            right: 12,
            bottom: navClearance(context),
            child: FloatingActionButton(
              heroTag: 'locate',
              tooltip: l.locateMe,
              onPressed: _locate,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPin extends StatelessWidget {
  const _ReportPin({required this.report, required this.category});
  final Report report;
  final Category category;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: category.name(context),
    child: GestureDetector(
      onTap: () => context.push('/reports/${report.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: category.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Icon(categoryIcon(category), color: Colors.white, size: 20),
      ),
    ),
  );
}

class _ClusterSheet extends ConsumerWidget {
  const _ClusterSheet({required this.reports});
  final List<Report> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scroll) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              localDigits(context, context.l10n.mapReportsHere(reports.length)),
              style: theme.textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final r = reports[i];
                final c = catalog.category(r.categoryId);
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(context.push('/reports/${r.id}'));
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: ReportPhoto(report: r, category: c, iconSize: 24),
                    ),
                  ),
                  title: Text(r.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${c.name(context)} · ${timeAgo(context, r.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: r.status == ReportStatus.resolved
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "Last 7 days ▾" — time range of the map, as a compact dropdown at the top right.
class _RangeMenu extends StatelessWidget {
  const _RangeMenu({required this.days, required this.onChanged});
  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final options = {1: l.mapLast24h, 7: l.mapLast7d, 30: l.mapLast30d};
    return PopupMenuButton<int>(
      key: const Key('map-range'),
      tooltip: options[days],
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final e in options.entries)
          PopupMenuItem(
            value: e.key,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontWeight: e.key == days ? FontWeight.w600 : FontWeight.w400,
                      color: e.key == days ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                if (e.key == days) Icon(Icons.check_rounded, size: 18, color: theme.colorScheme.primary),
              ],
            ),
          ),
      ],
      child: Material(
        elevation: 3,
        shadowColor: Colors.black26,
        color: theme.colorScheme.surface,
        shape: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(options[days]!, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
              Icon(Icons.expand_more_rounded, size: 20, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
