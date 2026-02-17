import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';

class LocationMapPage extends ConsumerWidget {
  const LocationMapPage({super.key});

  // Hardcoded coordinates for 8350 Potranco Rd, San Antonio, TX 78251
  static const double _lat = 29.4710;
  static const double _lng = -98.7130;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectInfo = ref.watch(projectInfoProvider);

    // Pull key info from provider
    String projectName = 'Project Location';
    String projectAddress = '8350 Potranco Rd, San Antonio, TX 78251';
    String parcelNumber = '';
    String lotSize = '';
    String zoning = '';
    String existingUse = '';

    for (final entry in projectInfo) {
      switch (entry.label) {
        case 'Project Name':
          projectName = entry.value;
        case 'Project Address':
          projectAddress = entry.value;
        case 'Parcel Number':
          parcelNumber = entry.value;
        case 'Lot Size':
          lotSize = entry.value;
        case 'Zoning Classification':
          zoning = entry.value;
        case 'Existing Use':
          existingUse = entry.value;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Tokens.accent, size: 22),
              const SizedBox(width: 8),
              Text('LOCATION MAP', style: AppTheme.heading),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Geo location and site information for $projectName',
            style: AppTheme.caption.copyWith(color: Tokens.textMuted),
          ),
          const SizedBox(height: Tokens.spaceLg),
          // Map + info layout
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _MapView(
                          lat: _lat,
                          lng: _lng,
                          address: projectAddress,
                          projectName: projectName,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _SiteInfoPanel(
                          projectName: projectName,
                          address: projectAddress,
                          parcelNumber: parcelNumber,
                          lotSize: lotSize,
                          zoning: zoning,
                          existingUse: existingUse,
                          lat: _lat,
                          lng: _lng,
                        ),
                      ),
                    ],
                  );
                }
                // Stacked layout for narrow screens
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 400,
                        child: _MapView(
                          lat: _lat,
                          lng: _lng,
                          address: projectAddress,
                          projectName: projectName,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SiteInfoPanel(
                        projectName: projectName,
                        address: projectAddress,
                        parcelNumber: parcelNumber,
                        lotSize: lotSize,
                        zoning: zoning,
                        existingUse: existingUse,
                        lat: _lat,
                        lng: _lng,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map Visualization ──────────────────────────────────────────
class _MapView extends StatelessWidget {
  final double lat;
  final double lng;
  final String address;
  final String projectName;

  const _MapView({
    required this.lat,
    required this.lng,
    required this.address,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          // Map header
          Row(
            children: [
              const Icon(Icons.map, size: 16, color: Tokens.accent),
              const SizedBox(width: 6),
              Text('PROJECT SITE', style: AppTheme.caption),
              const Spacer(),
              Text(
                '${lat.toStringAsFixed(4)}°N, ${lng.abs().toStringAsFixed(4)}°W',
                style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Map canvas
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radiusSm),
              child: _MapCanvas(lat: lat, lng: lng, projectName: projectName),
            ),
          ),
          const SizedBox(height: 12),
          // Address bar + open in maps button
          Row(
            children: [
              const Icon(Icons.place, size: 14, color: Tokens.chipRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: AppTheme.body.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _OpenMapsButton(lat: lat, lng: lng),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Custom-painted map visualization ───────────────────────────
class _MapCanvas extends StatelessWidget {
  final double lat;
  final double lng;
  final String projectName;

  const _MapCanvas({required this.lat, required this.lng, required this.projectName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        border: Border.all(color: Tokens.glassBorder),
      ),
      child: CustomPaint(
        painter: _MapPainter(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing pin
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Tokens.accent.withValues(alpha: 0.15),
                  border: Border.all(color: Tokens.accent.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.location_on, color: Tokens.accent, size: 28),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Tokens.bgDark.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  border: Border.all(color: Tokens.accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      projectName,
                      style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: Tokens.accent),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'San Antonio, TX 78251',
                      style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom painter for map grid/roads ──────────────────────────
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1A2D45)
      ..strokeWidth = 0.5;

    // Draw grid lines
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw "roads" — stylized lines representing a street grid
    final roadPaint = Paint()
      ..color = const Color(0xFF2A4060)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Horizontal roads
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.35),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      roadPaint,
    );

    // Vertical roads
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );

    // Draw block fills (lighter areas between roads)
    final blockPaint = Paint()..color = const Color(0xFF152238);
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.3 + 2, size.height * 0.35 + 2, size.width * 0.7 - 2, size.height * 0.65 - 2),
      blockPaint,
    );

    // Compass rose in top-right
    _drawCompass(canvas, Offset(size.width - 35, 35));

    // Scale bar at bottom-left
    _drawScaleBar(canvas, Offset(15, size.height - 20));
  }

  void _drawCompass(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFF3A5578)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 18, paint);

    final arrowPaint = Paint()
      ..color = const Color(0xFF00BCD4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // N arrow
    canvas.drawLine(center, Offset(center.dx, center.dy - 14), arrowPaint);
    // N label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(color: Color(0xFF00BCD4), fontSize: 8, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - 3, center.dy - 28));

    // Cardinal ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF3A5578)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx + 14, center.dy), Offset(center.dx + 18, center.dy), tickPaint); // E
    canvas.drawLine(Offset(center.dx, center.dy + 14), Offset(center.dx, center.dy + 18), tickPaint); // S
    canvas.drawLine(Offset(center.dx - 14, center.dy), Offset(center.dx - 18, center.dy), tickPaint); // W
  }

  void _drawScaleBar(Canvas canvas, Offset origin) {
    final paint = Paint()
      ..color = const Color(0xFF4A6A8A)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const barWidth = 60.0;
    canvas.drawLine(origin, Offset(origin.dx + barWidth, origin.dy), paint);
    canvas.drawLine(origin, Offset(origin.dx, origin.dy - 4), paint);
    canvas.drawLine(Offset(origin.dx + barWidth, origin.dy), Offset(origin.dx + barWidth, origin.dy - 4), paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '500 ft',
        style: TextStyle(color: Color(0xFF4A6A8A), fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(origin.dx + barWidth / 2 - 12, origin.dy - 14));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Open in Maps Button ────────────────────────────────────────
class _OpenMapsButton extends StatelessWidget {
  final double lat;
  final double lng;

  const _OpenMapsButton({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Tokens.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          border: Border.all(color: Tokens.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, size: 12, color: Tokens.accent),
            const SizedBox(width: 4),
            Text('Open in Maps', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.accent)),
          ],
        ),
      ),
    );
  }
}

// ── Site Info Panel ────────────────────────────────────────────
class _SiteInfoPanel extends StatelessWidget {
  final String projectName;
  final String address;
  final String parcelNumber;
  final String lotSize;
  final String zoning;
  final String existingUse;
  final double lat;
  final double lng;

  const _SiteInfoPanel({
    required this.projectName,
    required this.address,
    required this.parcelNumber,
    required this.lotSize,
    required this.zoning,
    required this.existingUse,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Coordinates card
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.my_location, size: 14, color: Tokens.accent),
                  const SizedBox(width: 6),
                  Text('COORDINATES', style: AppTheme.caption),
                ],
              ),
              const SizedBox(height: 12),
              _CoordRow(label: 'Latitude', value: '${lat.toStringAsFixed(6)}° N'),
              const SizedBox(height: 6),
              _CoordRow(label: 'Longitude', value: '${lng.abs().toStringAsFixed(6)}° W'),
              const SizedBox(height: 6),
              _CoordRow(label: 'UTM Zone', value: '14R 545,200 E / 3,261,800 N'),
              const SizedBox(height: 6),
              _CoordRow(label: 'Elevation', value: '~980 ft (299 m)'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Site details card
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Tokens.accent),
                  const SizedBox(width: 6),
                  Text('SITE DETAILS', style: AppTheme.caption),
                ],
              ),
              const SizedBox(height: 12),
              if (parcelNumber.isNotEmpty)
                _InfoRow(label: 'Parcel #', value: parcelNumber),
              if (lotSize.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoRow(label: 'Lot Size', value: lotSize),
              ],
              if (zoning.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoRow(label: 'Zoning', value: zoning),
              ],
              if (existingUse.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoRow(label: 'Prior Use', value: existingUse),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Nearby landmarks
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.near_me, size: 14, color: Tokens.accent),
                  const SizedBox(width: 6),
                  Text('NEARBY', style: AppTheme.caption),
                ],
              ),
              const SizedBox(height: 12),
              _NearbyItem(icon: Icons.local_fire_department, label: 'Fire Station #51', distance: '1.1 mi'),
              const SizedBox(height: 8),
              _NearbyItem(icon: Icons.local_hospital, label: 'Methodist Hospital Westover Hills', distance: '3.2 mi'),
              const SizedBox(height: 8),
              _NearbyItem(icon: Icons.local_hospital, label: 'Baptist Medical Center', distance: '8.5 mi'),
              const SizedBox(height: 8),
              _NearbyItem(icon: Icons.store, label: 'HEB Potranco', distance: '0.4 mi'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoordRow extends StatelessWidget {
  final String label;
  final String value;
  const _CoordRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted)),
        ),
        Expanded(
          child: Text(value, style: AppTheme.body.copyWith(fontSize: 12, fontFamily: 'monospace')),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted)),
        ),
        Expanded(
          child: Text(value, style: AppTheme.body.copyWith(fontSize: 12)),
        ),
      ],
    );
  }
}

class _NearbyItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String distance;
  const _NearbyItem({required this.icon, required this.label, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Tokens.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTheme.body.copyWith(fontSize: 11)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Tokens.glassFill,
            borderRadius: BorderRadius.circular(Tokens.radiusSm),
          ),
          child: Text(distance, style: AppTheme.caption.copyWith(fontSize: 9)),
        ),
      ],
    );
  }
}
