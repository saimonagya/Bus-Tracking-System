import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/theme/app_theme.dart';
import '../models/city_runner_models.dart';
import 'app_chrome.dart';

class TrackingMap extends StatelessWidget {
  const TrackingMap({
    super.key,
    required this.buses,
    required this.selectedBus,
    required this.viewerLocation,
    required this.onLocate,
    required this.locateLabel,
  });

  final List<BusState> buses;
  final BusState? selectedBus;
  final Coordinate? viewerLocation;
  final VoidCallback onLocate;
  final String locateLabel;

  @override
  Widget build(BuildContext context) {
    return CityPanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 260,
          child: Stack(
            children: [
              Positioned.fill(child: _mapSurface()),
              Positioned(
                right: 12,
                top: 12,
                child: FilledButton.icon(
                  onPressed: onLocate,
                  icon: const Icon(Icons.my_location, size: 17),
                  label: Text(locateLabel),
                  style: FilledButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: .72)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapSurface() {
    final canUseGoogleMap = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final bus = selectedBus;
    if (!canUseGoogleMap || bus == null || bus.route.isEmpty) {
      return CustomPaint(
        painter: _RoutePainter(bus: bus, buses: buses, viewerLocation: viewerLocation),
        child: const SizedBox.expand(),
      );
    }

    final markers = <Marker>{};
    for (final item in buses) {
      final position = item.position;
      if (position != null) {
        markers.add(
          Marker(
            markerId: MarkerId('bus-${item.id}'),
            position: LatLng(position.lat, position.lng),
            infoWindow: InfoWindow(title: item.name),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ),
        );
      }
    }
    for (final stop in bus.stops) {
      markers.add(
        Marker(
          markerId: MarkerId('stop-${stop.id}'),
          position: LatLng(stop.coordinate.lat, stop.coordinate.lng),
          infoWindow: InfoWindow(title: stop.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    if (viewerLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('viewer'),
          position: LatLng(viewerLocation!.lat, viewerLocation!.lng),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(bus.route.first.lat, bus.route.first.lng),
        zoom: 12,
      ),
      markers: markers,
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          color: AppTheme.accent,
          width: 5,
          points: bus.route.map((point) => LatLng(point.lat, point.lng)).toList(),
        ),
      },
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.bus, required this.buses, required this.viewerLocation});

  final BusState? bus;
  final List<BusState> buses;
  final Coordinate? viewerLocation;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF111111));
    final grid = Paint()
      ..color = const Color(0xFF242424)
      ..strokeWidth = 2;
    for (var i = -2; i < 9; i++) {
      canvas.drawLine(Offset(i * 70, 0), Offset(i * 70 + size.height, size.height), grid);
      canvas.drawLine(Offset(0, i * 52.0), Offset(size.width, i * 52.0 + 90), grid);
    }

    final routePaint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * .18, size.height * .34)
      ..cubicTo(size.width * .34, size.height * .35, size.width * .33, size.height * .67, size.width * .52, size.height * .63)
      ..cubicTo(size.width * .72, size.height * .6, size.width * .62, size.height * .28, size.width * .84, size.height * .23);
    canvas.drawPath(path, routePaint);
    _pin(canvas, Offset(size.width * .18, size.height * .34), Icons.directions_bus_filled);
    _pin(canvas, Offset(size.width * .52, size.height * .63), Icons.radio_button_checked);
    _pin(canvas, Offset(size.width * .84, size.height * .23), Icons.location_on);
  }

  void _pin(Canvas canvas, Offset center, IconData icon) {
    canvas.drawCircle(center, 16, Paint()..color = AppTheme.accent);
    final painter = TextPainter(
      text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontFamily: icon.fontFamily, color: Colors.white, fontSize: 18)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => true;
}
