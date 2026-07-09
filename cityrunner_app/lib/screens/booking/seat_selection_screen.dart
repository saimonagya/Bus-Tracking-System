import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_chrome.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final Set<int> _selectedSeats = {};
  static const int _totalSeats = 24;
  static const int _columns = 4;

  // Fallback demo seats, used only if the selected bus has no seat data.
  static const Set<int> _bookedSeats = {3, 7, 11, 15, 19};

  static const int _farePerSeat = 45;

  void _toggleSeat(int seatIndex, {required bool isBooked}) {
    if (isBooked) return;
    setState(() {
      if (_selectedSeats.contains(seatIndex)) {
        _selectedSeats.remove(seatIndex);
      } else {
        _selectedSeats.add(seatIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final bus = app.selectedBus;
    final apiSeats = bus?.seats ?? const [];
    final useApiSeats = apiSeats.isNotEmpty;
    final seatCount = useApiSeats ? apiSeats.length : _totalSeats;
    final fare = useApiSeats
        ? (bus!.stops.isNotEmpty ? bus.stops.last.fare : _farePerSeat)
        : _farePerSeat;
    final totalAmount =
        _selectedSeats.length * (fare == 0 ? _farePerSeat : fare);

    return PhoneFrame(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                IconCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => Navigator.pop(context),
                  size: 44,
                  iconSize: 18,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Your Seat',
                        style: TextStyle(
                          color: AppTheme.text,
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        bus?.name ?? 'CityRunner AC Bus',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Legend ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendItem(color: AppTheme.elevated, label: 'Available'),
                SizedBox(width: 20),
                _LegendItem(color: AppTheme.accent, label: 'Selected'),
                SizedBox(width: 20),
                _LegendItem(color: Color(0xFF3A3A3A), label: 'Booked'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Seat grid ───────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // Bus front indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.elevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2B2B2B)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          color: AppTheme.muted,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Front',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Seat rows
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: seatCount,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _columns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                      itemBuilder: (context, index) {
                        final isBooked = useApiSeats
                            ? apiSeats[index].isBooked
                            : _bookedSeats.contains(index);
                        final isSelected = _selectedSeats.contains(index);
                        final label = useApiSeats
                            ? apiSeats[index].label
                            : '${String.fromCharCode(65 + index ~/ _columns)}${index % _columns + 1}';

                        return _SeatTile(
                          label: label,
                          isBooked: isBooked,
                          isSelected: isSelected,
                          onTap: () => _toggleSeat(index, isBooked: isBooked),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom card ─────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2B2B2B)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedSeats.isEmpty ? '₹ --' : '₹$totalAmount',
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_selectedSeats.isNotEmpty)
                      Text(
                        '${_selectedSeats.length} seat${_selectedSeats.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: PrimaryButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _selectedSeats.isEmpty
                        ? null
                        : () => _confirmBooking(
                            context,
                            seatLabels: _selectedSeats
                                .map(
                                  (index) => useApiSeats
                                      ? apiSeats[index].label
                                      : '${String.fromCharCode(65 + index ~/ _columns)}${index % _columns + 1}',
                                )
                                .toList(),
                            totalAmount: totalAmount,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBooking(
    BuildContext context, {
    required List<String> seatLabels,
    required int totalAmount,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 22),
            SizedBox(width: 8),
            Text(
              'Booking Confirmed',
              style: TextStyle(
                color: AppTheme.text,
                fontFamily: 'Poppins',
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Seats ${seatLabels.join(', ')} • Total ₹$totalAmount',
          style: const TextStyle(
            color: AppTheme.muted,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.tracking,
                (route) => route.settings.name == AppRoutes.passengerHome,
              );
            },
            child: const Text(
              'Track My Bus',
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
}

// ─── Seat tile ────────────────────────────────────────────────────────────────
class _SeatTile extends StatefulWidget {
  const _SeatTile({
    required this.label,
    required this.isBooked,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isBooked;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SeatTile> createState() => _SeatTileState();
}

class _SeatTileState extends State<_SeatTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (widget.isBooked) {
      bgColor = const Color(0xFF2A2A2A);
      borderColor = const Color(0xFF333333);
      textColor = const Color(0xFF555555);
    } else if (widget.isSelected) {
      bgColor = AppTheme.accent;
      borderColor = AppTheme.accent;
      textColor = Colors.white;
    } else {
      bgColor = AppTheme.elevated;
      borderColor = const Color(0xFF2B2B2B);
      textColor = AppTheme.text;
    }

    return GestureDetector(
      onTapDown: widget.isBooked
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.isBooked
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: widget.isBooked
          ? null
          : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_seat_rounded, color: textColor, size: 20),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Legend item ──────────────────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2B2B2B)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.muted,
            fontFamily: 'Poppins',
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
