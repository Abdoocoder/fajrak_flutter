import 'package:flutter/material.dart';
import '../common/filter_chips.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.monthLabels,
    required this.onMonthSelected,
  });

  final int selectedMonth;
  final List<String> monthLabels;
  final Function(int) onMonthSelected;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = monthLabels[selectedMonth - 1];
    return AppFilterChips(
      options: monthLabels,
      selected: selectedLabel,
      onSelected: (label) {
        final idx = monthLabels.indexOf(label);
        if (idx >= 0) onMonthSelected(idx + 1);
      },
      padding: EdgeInsets.zero,
    );
  }
}
