import 'package:amud/core/adaptive.dart';
import 'package:amud/core/dpad_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings picker opens as a full page and works with the D-pad', (tester) async {
    String? chosen;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => DpadNavigation(child: child!),
      home: Builder(builder: (context) => Scaffold(
        body: Column(children: [
          const Text('Settings underneath'),
          TextButton(
            autofocus: true,
            onPressed: () async {
              chosen = await showAdaptivePicker<String>(
                context,
                title: 'Default Siddur',
                selected: 'two',
                options: const [('one', 'One'), ('two', 'Two'), ('three', 'Three')],
              );
            },
            child: const Text('Open picker'),
          ),
        ]),
      )),
    ));

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Default Siddur'), findsOneWidget);
    expect(find.text('Settings underneath'), findsNothing);

    expect(Focus.of(tester.element(find.text('Two'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('Three'))).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(chosen, 'three');
    expect(find.text('Settings underneath'), findsOneWidget);
  });
}
