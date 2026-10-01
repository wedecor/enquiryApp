import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import 'calendar_event.dart';
import 'calendar_panel_controls.dart';

const Map<CalendarFormat, String> _formats = {
  CalendarFormat.month: 'Month',
  CalendarFormat.twoWeeks: '2 weeks',
  CalendarFormat.week: 'Week',
};

/// Glass month panel around [TableCalendar]: split-weight month title with
/// tactile chevrons, gold selected day, dot markers and a status legend.
class CalendarMonthPanel extends StatefulWidget {
  const CalendarMonthPanel({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.eventLoader,
    required this.markerBuilder,
    required this.legend,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onFormatChanged,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final List<CalendarEvent> Function(DateTime day) eventLoader;
  final Widget? Function(BuildContext context, DateTime day, List<CalendarEvent> events)
  markerBuilder;

  /// (label, colour) pairs shown under the grid.
  final List<(String, Color)> legend;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final ValueChanged<CalendarFormat> onFormatChanged;

  @override
  State<CalendarMonthPanel> createState() => _CalendarMonthPanelState();
}

class _CalendarMonthPanelState extends State<CalendarMonthPanel> {
  late final ValueNotifier<DateTime> _visibleMonth = ValueNotifier(widget.focusedDay);
  PageController? _pageController;

  @override
  void didUpdateWidget(covariant CalendarMonthPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedDay != widget.focusedDay) _visibleMonth.value = widget.focusedDay;
  }

  @override
  void dispose() {
    _visibleMonth.dispose();
    super.dispose();
  }

  void _turnPage({required bool forward}) {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;
    if (AppMotion.reduced(context)) {
      final page = controller.page?.round() ?? controller.initialPage;
      controller.jumpToPage(forward ? page + 1 : page - 1);
    } else if (forward) {
      controller.nextPage(duration: AppMotion.standard, curve: AppMotion.standardCurve);
    } else {
      controller.previousPage(duration: AppMotion.standard, curve: AppMotion.standardCurve);
    }
  }

  void _cycleFormat() {
    final keys = _formats.keys.toList();
    final next = keys[(keys.indexOf(widget.calendarFormat) + 1) % keys.length];
    widget.onFormatChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final t = theme.textTheme;
    final reduced = AppMotion.reduced(context);

    final dayStyle = (t.bodyMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final dowStyle = (t.labelSmall ?? const TextStyle()).copyWith(
      letterSpacing: 1.2,
      color: cs.onSurfaceVariant,
    );

    return GlassPanel(
      strong: true,
      shadow: true,
      borderRadius: AppRadius.xLarge,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space3,
        AppTokens.space2,
        AppTokens.space2,
        AppTokens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppTokens.space2),
                  child: ValueListenableBuilder<DateTime>(
                    valueListenable: _visibleMonth,
                    builder: (context, month, _) => CalendarMonthTitle(month: month),
                  ),
                ),
              ),
              CalendarChevronButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous',
                onTap: () => _turnPage(forward: false),
              ),
              CalendarChevronButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next',
                onTap: () => _turnPage(forward: true),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space1),
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: widget.focusedDay,
            selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
            calendarFormat: widget.calendarFormat,
            availableCalendarFormats: _formats,
            eventLoader: widget.eventLoader,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerVisible: false,
            rowHeight: 50,
            daysOfWeekHeight: 28,
            pageAnimationEnabled: !reduced,
            // table_calendar's AnimatedSize asserts on a zero duration.
            formatAnimationDuration: reduced ? const Duration(milliseconds: 1) : AppMotion.standard,
            formatAnimationCurve: AppMotion.standardCurve,
            onCalendarCreated: (controller) => _pageController = controller,
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date).toUpperCase(),
              weekdayStyle: dowStyle,
              weekendStyle: dowStyle.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.fromLTRB(5, 2, 5, 10),
              defaultTextStyle: dayStyle,
              weekendTextStyle: dayStyle.copyWith(
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
              ),
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: s.accent.withValues(alpha: 0.75), width: 1.4),
              ),
              todayTextStyle: dayStyle.copyWith(fontWeight: FontWeight.w800, color: s.accentInk),
              selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: s.accentGradient,
                boxShadow: [
                  BoxShadow(
                    color: s.accent.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              selectedTextStyle: dayStyle.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColorScheme.brandCharcoal,
              ),
            ),
            onDaySelected: widget.onDaySelected,
            onPageChanged: (focusedDay) {
              _visibleMonth.value = focusedDay;
              widget.onPageChanged(focusedDay);
            },
            onFormatChanged: widget.onFormatChanged,
            calendarBuilders: CalendarBuilders(markerBuilder: widget.markerBuilder),
          ),
          const SizedBox(height: AppTokens.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppTokens.space2),
                  child: Wrap(
                    spacing: AppTokens.space3,
                    runSpacing: AppTokens.space1 + 2,
                    children: [
                      for (final (label, color) in widget.legend)
                        CalendarLegendItem(label: label, color: color),
                    ],
                  ),
                ),
              ),
              CalendarFormatChip(label: _formats[widget.calendarFormat] ?? '', onTap: _cycleFormat),
            ],
          ),
        ],
      ),
    );
  }
}
