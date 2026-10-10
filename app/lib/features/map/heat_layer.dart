import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models.dart';

class HeatCluster {
  HeatCluster(this.center, this.reports);
  final LatLng center;
  final List<Report> reports;
}

/// Groups reports into a grid of [cellPx] world pixels at [zoom]. Grid cells are anchored to the
/// world (not the screen) so clusters don't jump while panning; they're recomputed on zoom change.
List<HeatCluster> clusterReports(List<Report> reports, MapCamera camera, int zoom, {double cellPx = 72}) {
  final cells = <(int, int), List<Report>>{};
  for (final r in reports) {
    final p = camera.projectAtZoom(LatLng(r.lat, r.lng), zoom.toDouble());
    cells.putIfAbsent(((p.dx / cellPx).floor(), (p.dy / cellPx).floor()), () => []).add(r);
  }
  return [
    for (final group in cells.values)
      HeatCluster(
        LatLng(
          group.fold<double>(0, (s, r) => s + r.lat) / group.length,
          group.fold<double>(0, (s, r) => s + r.lng) / group.length,
        ),
        group,
      ),
  ];
}

/// Snapchat-style heat blobs: soft radial gradients, blue -> yellow -> red by density.
class HeatLayer extends StatelessWidget {
  const HeatLayer({required this.clusters, required this.clusterZoom, super.key, this.showCounts = false});
  final List<HeatCluster> clusters;
  final int clusterZoom;
  final bool showCounts;

  static double radiusFor(int count, double scale) => (26 + math.sqrt(count) * 11).clamp(26, 90) * scale;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: camera.size,
          painter: _HeatPainter(
            camera: camera,
            clusters: clusters,
            scale: camera.getZoomScale(camera.zoom, clusterZoom.toDouble()).clamp(0.6, 1.6),
            showCounts: showCounts,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter({
    required this.camera,
    required this.clusters,
    required this.scale,
    required this.showCounts,
    required this.textDirection,
  });

  final MapCamera camera;
  final List<HeatCluster> clusters;
  final double scale;
  final bool showCounts;
  final TextDirection textDirection;

  static const _stops = [Color(0xFF3D8BFF), Color(0xFF34D1BF), Color(0xFFFFD43B), Color(0xFFFF8A00), Color(0xFFFF2D55)];

  static Color colorFor(double t) {
    final x = t.clamp(0.0, 1.0) * (_stops.length - 1);
    final i = x.floor().clamp(0, _stops.length - 2);
    return Color.lerp(_stops[i], _stops[i + 1], x - i)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (clusters.isEmpty) return;
    final maxCount = clusters.fold<int>(1, (m, c) => math.max(m, c.reports.length));
    final paint = Paint();
    final sorted = [...clusters]..sort((a, b) => a.reports.length.compareTo(b.reports.length));

    for (final c in sorted) {
      final o = camera.getOffsetFromOrigin(c.center);
      final r = HeatLayer.radiusFor(c.reports.length, scale);
      if (o.dx < -r || o.dy < -r || o.dx > size.width + r || o.dy > size.height + r) continue;
      final t = maxCount <= 1 ? 0.3 : math.log(c.reports.length) / math.log(maxCount);
      final color = colorFor(t);
      paint.shader = ui.Gradient.radial(
        o,
        r,
        [color.withValues(alpha: 0.85), color.withValues(alpha: 0.45), color.withValues(alpha: 0)],
        const [0, 0.55, 1],
      );
      canvas.drawCircle(o, r, paint);

      if (showCounts && c.reports.length > 1) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${c.reports.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
          textDirection: textDirection,
        )..layout();
        tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.camera != camera || old.clusters != clusters || old.scale != scale || old.showCounts != showCounts;
}

class HeatLegend extends StatelessWidget {
  const HeatLegend({required this.few, required this.many, super.key});
  final String few;
  final String many;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(few, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 8),
        Container(
          width: 80,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(colors: _HeatPainter._stops),
          ),
        ),
        const SizedBox(width: 8),
        Text(many, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}
