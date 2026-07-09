import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_chrome.dart';
import '../../widgets/tracking_map.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  // Static bus options for the booking sheet
  int _selectedBusOption = 1; // 0=Express, 1=AC, 2=Ordinary

  static const _busOptions = [
    _BusOption(name: 'City Express', type: 'Express Bus', fare: 35),
    _BusOption(name: 'CityRunner AC Bus', type: 'AC Bus', fare: 45),
    _BusOption(name: 'City Ordinary', type: 'Ordinary Bus', fare: 25),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final selectedBus = app.selectedBus;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main scrollable content ──────────────────────────────────
            SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        IconCircleButton(
                          icon: Icons.menu_rounded,
                          onPressed: () => _openMenu(context),
                          size: 46,
                        ),
                        const Spacer(),
                        IconCircleButton(
                          icon: Icons.notifications_outlined,
                          onPressed: () => _openNotifications(context),
                          size: 46,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Location cards ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: CityPanel(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Current location row
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  color: AppTheme.accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Location',
                                      style: TextStyle(
                                        color: AppTheme.muted,
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Gangtok, Sikkim',
                                      style: TextStyle(
                                        color: AppTheme.text,
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                const SizedBox(width: 17),
                                Container(
                                  width: 2,
                                  height: 20,
                                  color: const Color(0xFF2B2B2B),
                                ),
                              ],
                            ),
                          ),

                          // Destination row
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppTheme.text,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Destination',
                                      style: TextStyle(
                                        color: AppTheme.muted,
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Choose Destination',
                                      style: TextStyle(
                                        color: AppTheme.muted,
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.search_rounded,
                                color: AppTheme.muted,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Map ─────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 320,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: TrackingMap(
                                buses: app.visibleBuses,
                                selectedBus: selectedBus,
                                viewerLocation: app.passengerLocation,
                                onLocate: () => context
                                    .read<AppProvider>()
                                    .locatePassenger(),
                                locateLabel: 'Locate',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Booking sheet ───────────────────────────────────────
                  const SizedBox(height: 16),

                  _BookingSheet(
                    busOptions: _busOptions,
                    selectedIndex: _selectedBusOption,
                    onSelectBus: (i) => setState(() => _selectedBusOption = i),
                    onBook: selectedBus == null
                        ? null
                        : () => Navigator.pushNamed(
                            context,
                            AppRoutes.seatSelection,
                          ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showAppMenuSheet(
      context,
      name: 'Passenger',
      subtitle: 'Move Cities. Move People.',
      actions: [
        MenuAction(
          icon: Icons.confirmation_number_outlined,
          label: 'My Tickets',
          onTap: () => _showComingSoon(context, 'My Tickets'),
        ),
        MenuAction(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Payment Methods',
          onTap: () => _showComingSoon(context, 'Payment Methods'),
        ),
        MenuAction(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () => _showComingSoon(context, 'Settings'),
        ),
        MenuAction(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          onTap: () => _showComingSoon(context, 'Help & Support'),
        ),
        MenuAction(
          icon: Icons.swap_horiz_rounded,
          label: 'Switch Role',
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.roleSelection,
            (_) => false,
          ),
        ),
      ],
    );
  }

  void _openNotifications(BuildContext context) {
    showNotificationsSheet(
      context,
      items: const [
        NotificationItemData(
          icon: Icons.directions_bus_rounded,
          title: 'Your bus is arriving',
          subtitle: 'CityRunner AC Bus is 4 minutes away.',
          time: 'now',
          accent: true,
        ),
        NotificationItemData(
          icon: Icons.local_offer_outlined,
          title: '20% off your next ride',
          subtitle: 'Use code CITY20 at checkout.',
          time: '2h ago',
        ),
        NotificationItemData(
          icon: Icons.info_outline_rounded,
          title: 'Route update',
          subtitle: 'Gangtok -> Ranipool now stops at Deorali.',
          time: 'Yesterday',
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }
}

// ─── Bus option data ──────────────────────────────────────────────────────────
class _BusOption {
  const _BusOption({
    required this.name,
    required this.type,
    required this.fare,
  });

  final String name;
  final String type;
  final int fare;
}

// ─── Booking sheet ────────────────────────────────────────────────────────────
class _BookingSheet extends StatelessWidget {
  const _BookingSheet({
    required this.busOptions,
    required this.selectedIndex,
    required this.onSelectBus,
    required this.onBook,
  });

  final List<_BusOption> busOptions;
  final int selectedIndex;
  final ValueChanged<int> onSelectBus;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final selectedFare = busOptions[selectedIndex].fare;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2B2B2B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bus option cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: List.generate(busOptions.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i < busOptions.length - 1 ? 10 : 0,
                  ),
                  child: _BusOptionCard(
                    option: busOptions[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelectBus(i),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          const Divider(color: Color(0xFF2B2B2B), height: 1),

          // Payment method row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.elevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2B2B2B)),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Payment Method',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),
                ),
                const Text(
                  'UPI',
                  style: TextStyle(
                    color: AppTheme.text,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.muted,
                  size: 20,
                ),
              ],
            ),
          ),

          // Divider
          const Divider(color: Color(0xFF2B2B2B), height: 1),

          // Book button
          Padding(
            padding: const EdgeInsets.all(16),
            child: _BookButton(fare: selectedFare, onPressed: onBook),
          ),
        ],
      ),
    );
  }
}

// ─── Bus option card ──────────────────────────────────────────────────────────
class _BusOptionCard extends StatefulWidget {
  const _BusOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _BusOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_BusOptionCard> createState() => _BusOptionCardState();
}

class _BusOptionCardState extends State<_BusOptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.selected ? AppTheme.accent : AppTheme.elevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected
                  ? AppTheme.accent
                  : const Color(0xFF2B2B2B),
            ),
          ),
          child: Row(
            children: [
              // Bus icon
              Icon(
                Icons.directions_bus_rounded,
                color: widget.selected ? Colors.white : AppTheme.muted,
                size: 22,
              ),
              const SizedBox(width: 12),
              // Name & type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.name,
                      style: TextStyle(
                        color: widget.selected ? Colors.white : AppTheme.text,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.option.type,
                      style: TextStyle(
                        color: widget.selected
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.muted,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Fare
              Text(
                '₹${widget.option.fare}',
                style: TextStyle(
                  color: widget.selected ? Colors.white : AppTheme.text,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Book button ──────────────────────────────────────────────────────────────
class _BookButton extends StatefulWidget {
  const _BookButton({required this.fare, required this.onPressed});

  final int fare;
  final VoidCallback? onPressed;

  @override
  State<_BookButton> createState() => _BookButtonState();
}

class _BookButtonState extends State<_BookButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Book Ticket',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.confirmation_number_outlined,
                color: Colors.black,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
