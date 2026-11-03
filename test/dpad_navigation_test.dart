import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amud/core/dpad_navigation.dart';

void main() {
  testWidgets('directional keys move focus in reading order', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DpadNavigation(
          child: Column(
            children: [
              TextButton(onPressed: _noop, autofocus: true, child: Text('First')),
              TextButton(onPressed: _noop, child: Text('Second')),
            ],
          ),
        ),
      ),
    ));

    expect(Focus.of(tester.element(find.text('First'))).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(Focus.of(tester.element(find.text('Second'))).hasFocus, isTrue);
  });

  testWidgets('D-pad SELECT activates the focused control', (tester) async {
    var activated = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DpadNavigation(
          child: TextButton(
            autofocus: true,
            onPressed: () => activated = true,
            child: const Text('Activate'),
          ),
        ),
      ),
    ));

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(activated, isTrue);
  });
}

void _noop() {}
