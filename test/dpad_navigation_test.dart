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

  testWidgets('custom reader rows show an outline and activate with SELECT', (tester) async {
    var activated = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DpadNavigation(
          child: DpadFocusable(
            autofocus: true,
            onActivate: () => activated = true,
            child: const SizedBox(width: 140, height: 48, child: Text('Reader row')),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final outline = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).last);
    final decoration = outline.decoration as BoxDecoration;
    expect(decoration.border, isA<Border>());
    expect((decoration.border as Border).top.width, 2.5);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(activated, isTrue);
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

  testWidgets('reader scroll focus does not swallow keys from focused buttons', (tester) async {
    var secondActivated = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DpadNavigation(
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (!node.hasPrimaryFocus) return KeyEventResult.ignored;
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
                node.nextFocus();
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextButton(onPressed: _noop, child: const Text('Reader action one')),
              TextButton(onPressed: () => secondActivated = true, child: const Text('Reader action two')),
            ]),
          ),
        ),
      ),
    ));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(secondActivated, isTrue);
  });

}

void _noop() {}
