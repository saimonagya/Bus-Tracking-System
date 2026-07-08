import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_chrome.dart';
import '../../widgets/tracking_map.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    final selectedBus = app.selectedBus;

    return PhoneFrame(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.accent,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back",
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "Passenger",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const SectionTitle(
              title: "Where are you going?",
              subtitle: "Book your next ride",
            ),

            const SizedBox(height: 18),

            // LOCATION CARD
            const CityPanel(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: AppTheme.accent,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Current Location",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Choose Destination",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // MAP
            TrackingMap(
              buses: app.visibleBuses,
              selectedBus: selectedBus,
              viewerLocation: app.passengerLocation,
              onLocate: () {
                context.read<AppProvider>().locatePassenger();
              },
              locateLabel: "Locate",
            ),

            const SizedBox(height: 22),

            const SectionTitle(
              title: "Available Buses",
              subtitle: "Choose your preferred route",
            ),

            const SizedBox(height: 14),

            if (app.visibleBuses.isEmpty)
              const CityPanel(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No buses available",
                    ),
                  ),
                ),
              )
            else
              ...app.visibleBuses.map(
                (bus) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      app.selectBus(bus.id);
                    },
                    child: CityPanel(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_bus,
                                color: AppTheme.accent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bus.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      bus.routeName,
                                      style: const TextStyle(
                                        color: AppTheme.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (bus.id == selectedBus?.id)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.accent,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: StatTile(
                                  label: "Seats",
                                  value:
                                      "${bus.availableSeats}/${bus.seatCapacity}",
                                  icon: Icons.event_seat,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatTile(
                                  label: "ETA",
                                  value:
                                      "${bus.etaMinutes ?? '--'} min",
                                  icon: Icons.timer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 22),

            const SectionTitle(
              title: "Fare Details",
              subtitle: "Estimated trip price",
            ),

            const SizedBox(height: 12),

            CityPanel(
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Estimated Fare",
                    style: TextStyle(
                      color: AppTheme.muted,
                    ),
                  ),
                  Text(
                    selectedBus == null
                        ? "₹ --"
                        : "₹ ${selectedBus.stops.isNotEmpty ? selectedBus.stops.first.fare : 50}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const SectionTitle(
              title: "Payment Method",
            ),

            const SizedBox(height: 12),

            const CityPanel(
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.accent,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Wallet / UPI",
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),

            const SizedBox(height: 28),

            GradientButton(
              label: "Book Ticket",
              icon: Icons.confirmation_number,
              onPressed: selectedBus == null
                  ? null
                  : () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.seatSelection,
                      );
                    },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}