import 'dart:io';

import 'package:amud/core/dpad_navigation.dart';
import 'package:amud/core/format.dart';
import 'package:amud/core/l10n.dart';
import 'package:amud/core/providers.dart';
import 'package:amud/core/settings.dart';
import 'package:amud/core/storage.dart';
import 'package:amud/core/theme.dart';
import 'package:amud/features/calendar/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hebcal/hebcal.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(initHebcal);

  testWidgets('calendar stays usable and date cells respond to D-pad on a flip phone', (tester) async {
    tester.view.physicalSize = const Size(240, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late Storage storage;
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('calendar_dpad');
      addTearDown(() => dir.delete(recursive: true));
      storage = await Storage.openAt(dir.path, name: 'calendar_dpad');
    });
    final now = tz.TZDateTime(tz.getLocation('America/New_York'), 2026, 11, 20, 12);
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(storage),
      nowProvider.overrideWith((ref) => Stream.value(now)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(const AppSettings(), Brightness.light),
        builder: (context, child) => AppText(
          lang: UiLanguage.en,
          ashkenazi: true,
          child: DpadNavigation(child: child!),
        ),
        home: const CalendarScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('20'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('20'))).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('21'))).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
