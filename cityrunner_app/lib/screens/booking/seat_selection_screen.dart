import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_chrome.dart';
import '../../widgets/seat_grid.dart';

class SeatSelectionScreen extends StatelessWidget {
  const SeatSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final bus = app.selectedBus;

    return PhoneFrame(
      child: Stack(
        children: [
          SingleChildScrollView(
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
                        'Seat View',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (bus == null)
                  const CityPanel(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Choose a bus first.')),
                    ),
                  )
                else ...[
                  CityPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bus.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(bus.routeName, style: const TextStyle(color: AppTheme.muted)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _InlineStat(
                                label: 'Available',
                                value: '${bus.availableSeats}',
                                icon: Icons.event_available,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _InlineStat(
                                label: 'Booked',
                                value: '${bus.bookedSeats}',
                                icon: Icons.event_busy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(
                    title: 'Seats',
                    subtitle: 'Passenger booking is not enabled by the backend yet.',
                  ),
                  const SizedBox(height: 12),
                  CityPanel(
                    child: SeatGrid(
                      seats: bus.seats,
                      readOnly: true,
                      onToggleSeat: (_) {},
                      busyAction: app.busyAction,
                    ),
                  ),
                  const SizedBox(height: 22),
                  GradientButton(
                    label: 'Track Bus',
                    icon: Icons.route,
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.tracking),
                  ),
                ],
              ],
            ),
          ),
          CitySnackHost(
            message: app.errorMessage,
            isError: true,
            onDismiss: () => context.read<AppProvider>().clearMessages(),
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
