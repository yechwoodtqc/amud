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

  testWidgets('hardware Go Back key pops the currently focused route', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DpadNavigation(
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: TextButton(
                    autofocus: true,
                    onPressed: _noop,
                    child: const Text('Details'),
                  ),
                ),
              )),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);

    await tester.sendKeyEvent(
      LogicalKeyboardKey.goBack,
      physicalKey: PhysicalKeyboardKey.escape,
    );
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('D-pad Up and Down leave a text field for the next control', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DpadNavigation(
        child: Scaffold(
          body: Column(children: [
            const TextField(autofocus: true, maxLines: 2),
            TextButton(onPressed: _noop, child: const Text('Next control')),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>(), isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('Next control'))).hasFocus, isTrue);
  });

  testWidgets('slider adjusts with Left and Right and leaves with Up and Down', (tester) async {
    var value = 0.5;
    await tester.pumpWidget(MaterialApp(
      home: DpadNavigation(
        child: Scaffold(
          body: Column(children: [
            Slider(
              autofocus: true,
              value: value,
              onChanged: (v) => value = v,
            ),
            TextButton(onPressed: _noop, child: const Text('After slider')),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, greaterThan(0.5));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('After slider'))).hasFocus, isTrue);
  });

  testWidgets('reader ancestor does not swallow SELECT from a focused button', (tester) async {
    var activated = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DpadNavigation(
          child: Focus(
            onKeyEvent: (node, event) {
              // The reader's scroll handler must ignore events bubbling from
              // a focused descendant, so the button can receive ActivateIntent.
              if (!node.hasPrimaryFocus) return KeyEventResult.ignored;
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextButton(
              autofocus: true,
              onPressed: () => activated = true,
              child: const Text('Reader action'),
            ),
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
