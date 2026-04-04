import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/presentation/features/workout/providers/equipment_detail_provider.dart';
import 'package:tapem/presentation/widgets/charts/e1rm_progress_chart.dart';

void main() {
  testWidgets('renders chart with a single e1RM point', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: E1rmProgressChart(
            points: [
              E1rmDataPoint(
                sessionDayAnchor: '2026-03-01',
                e1rm: 90,
                weightKg: 75,
                reps: 6,
              ),
            ],
            emptyMessage: 'empty',
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('e1rm-progress-chart')), findsOneWidget);
    expect(find.byKey(const Key('e1rm-progress-empty')), findsNothing);
  });
}
