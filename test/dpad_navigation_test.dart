import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amud/core/dpad_navigation.dart';
import 'package:amud/core/dpad_focus.dart';

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

  testWidgets('D-pad SELECT and Enter activate the focused control', (tester) async {
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

    activated = false;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activated, isTrue);
  });
  testWidgets('custom reader surfaces have an outline and activate with SELECT', (tester) async {
    var activated = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DpadNavigation(
          child: DpadFocusable(
            autofocus: true,
            onActivate: () => activated = true,
            child: const Padding(padding: EdgeInsets.all(12), child: Text('Passage')),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final focus = Focus.of(tester.element(find.text('Passage')));
    expect(focus.hasFocus, isTrue);
    final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).last);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border!.top.color, isNot(Colors.transparent));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(activated, isTrue);
  });

}

void _noop() {}
