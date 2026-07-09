import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_chrome.dart';
import '../../widgets/tracking_map.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final bus = app.selectedBus;

    if (bus == null) {
      return const PhoneFrame(
        child: Center(
          child: Text(
            'No active booking found',
            style: TextStyle(color: AppTheme.muted, fontFamily: 'Poppins'),
          ),
        ),
      );
    }

    final eta = bus.etaMinutes ?? 4;
    final driverName = bus.assignedDriver?.displayName ?? 'Driver';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bus info card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: CityPanel(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => Navigator.pop(context),
                      size: 40,
                      iconSize: 16,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus.name,
                            style: const TextStyle(
                              color: AppTheme.text,
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            bus.routeName,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // LIVE badge
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              const Color(0xFF1A3A1A),
                              const Color(0xFF0D2A0D),
                              _pulseAnim.value,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color.lerp(
                                Colors.green,
                                Colors.green.withValues(alpha: 0.5),
                                _pulseAnim.value,
                              )!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Arrival card ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your Bus is Arriving in $eta Minutes.',
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Map ────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: TrackingMap(
                    buses: app.visibleBuses,
                    selectedBus: bus,
                    viewerLocation: app.passengerLocation,
                    onLocate: () =>
                        context.read<AppProvider>().locatePassenger(),
                    locateLabel: 'Locate',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Driver card ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: CityPanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Driver avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.elevated,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppTheme.text,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: const TextStyle(
                                  color: AppTheme.text,
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppTheme.accent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    '4.8',
                                    style: TextStyle(
                                      color: AppTheme.muted,
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    bus.registrationNumber,
                                    style: const TextStyle(
                                      color: AppTheme.muted,
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Phone button
                        IconCircleButton(
                          icon: Icons.call_outlined,
                          onPressed: () => _callDriver(context, driverName),
                          size: 44,
                          iconSize: 20,
                        ),
                        const SizedBox(width: 8),
                        // Menu button
                        IconCircleButton(
                          icon: Icons.more_vert_rounded,
                          onPressed: () => _openTripOptions(context),
                          size: 44,
                          iconSize: 20,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Share location button
                    PrimaryButton(
                      label: 'Share Location',
                      icon: Icons.share_location_rounded,
                      onPressed: () => _shareLocation(context, bus.name),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _callDriver(BuildContext context, String driverName) {
    const phoneNumber = '+91 98765 43210';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Call $driverName',
          style: const TextStyle(color: AppTheme.text, fontFamily: 'Poppins'),
        ),
        content: const Text(
          phoneNumber,
          style: TextStyle(
            color: AppTheme.muted,
            fontFamily: 'Poppins',
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.muted, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: phoneNumber));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Number copied to clipboard.')),
              );
            },
            child: const Text(
              'Copy Number',
              style: TextStyle(
                color: AppTheme.accent,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTripOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.panel,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2B2B2B)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.report_gmailerrorred_rounded,
                      color: AppTheme.text,
                    ),
                    title: const Text(
                      'Report an Issue',
                      style: TextStyle(
                        color: AppTheme.text,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thanks — our team will look into it.'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.text,
                    ),
                    title: const Text(
                      'Bus Details',
                      style: TextStyle(
                        color: AppTheme.text,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    onTap: () => Navigator.pop(sheetContext),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.cancel_outlined,
                      color: Color(0xFFE5484D),
                    ),
                    title: const Text(
                      'Cancel Trip',
                      style: TextStyle(
                        color: Color(0xFFE5484D),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _shareLocation(BuildContext context, String busName) {
    final link =
        'https://cityrunner.app/track/${busName.replaceAll(' ', '-').toLowerCase()}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tracking link copied — share it with anyone.'),
      ),
    );
  }
}
