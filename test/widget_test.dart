import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_adventure/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MathAdventureApp());

    expect(find.text('Math Adventure'), findsOneWidget);
  });
}
