import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_chrome.dart';
import '../../widgets/tracking_map.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final bus = app.selectedBus;

    if (bus == null) {
      return const PhoneFrame(
        child: Center(
          child: Text('No active booking found'),
        ),
      );
    }

    return PhoneFrame(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Live Tracking',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.gps_fixed,
                  color: AppTheme.accent,
                ),
              ],
            ),

            const SizedBox(height: 20),

            TrackingMap(
              buses: app.visibleBuses,
              selectedBus: bus,
              viewerLocation: app.passengerLocation,
              onLocate: () {
                context.read<AppProvider>().locatePassenger();
              },
              locateLabel: 'Locate',
            ),

            const SizedBox(height: 20),

            CityPanel(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_bus,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bus.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              bus.routeName,
                              style: const TextStyle(
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'ETA',
                    value: '${bus.etaMinutes ?? "--"} min',
                    icon: Icons.timer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    label: 'Seats Left',
                    value: '${bus.availableSeats}',
                    icon: Icons.event_seat,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const SectionTitle(
              title: 'Driver Details',
              subtitle: 'Assigned driver information',
            ),

            const SizedBox(height: 12),

            CityPanel(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.accent,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.assignedDriver?.displayName ??
                              'Driver Not Assigned',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          bus.registrationNumber,
                          style: const TextStyle(
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.call),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const SectionTitle(
              title: 'Upcoming Stops',
              subtitle: 'Route progress',
            ),

            const SizedBox(height: 12),

            CityPanel(
              child: Column(
                children: List.generate(
                  bus.stops.length,
                  (index) {
                    final stop = bus.stops[index];

                    final isCurrent =
                        index == (bus.currentStopIndex ?? 0);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: isCurrent
                            ? AppTheme.accent
                            : AppTheme.elevated,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ),
                      title: Text(stop.name),
                      subtitle: Text(
                        'Fare ₹${stop.fare}',
                      ),
                      trailing: isCurrent
                          ? const Icon(
                              Icons.location_on,
                              color: AppTheme.accent,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            GradientButton(
              label: 'Share Trip',
              icon: Icons.share,
              onPressed: () {},
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Support'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}