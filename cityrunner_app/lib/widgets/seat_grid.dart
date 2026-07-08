import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/city_runner_models.dart';

class SeatGrid extends StatelessWidget {
  const SeatGrid({
    super.key,
    required this.seats,
    required this.readOnly,
    required this.onToggleSeat,
    required this.busyAction,
  });

  final List<Seat> seats;
  final bool readOnly;
  final ValueChanged<int> onToggleSeat;
  final String? busyAction;

  @override
  Widget build(BuildContext context) {
    final sorted = [...seats]..sort((a, b) => a.id.compareTo(b.id));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final seat = sorted[index];
        final busy = busyAction == 'seat-${seat.id}';
        final color = seat.isBooked ? const Color(0xFF525252) : AppTheme.elevated;
        return InkWell(
          onTap: readOnly || busy ? null : () => onToggleSeat(seat.id),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: seat.isBooked ? const Color(0xFF666666) : const Color(0xFF343434)),
            ),
            child: busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(seat.label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        );
      },
    );
  }
}
