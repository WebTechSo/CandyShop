import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sweet Stop label renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Text('Sweet Stop')),
    ));

    expect(find.text('Sweet Stop'), findsOneWidget);
  });
}
