import 'package:amud/app.dart';
import 'package:amud/core/dpad_navigation.dart';
import 'package:amud/core/l10n.dart';
import 'package:amud/core/search.dart';
import 'package:amud/core/settings.dart';
import 'package:amud/core/theme.dart';
import 'package:amud/features/settings/nav_tabs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact Settings header, search and bottom tabs fit a small screen', (tester) async {
    tester.view.physicalSize = const Size(240, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildTheme(const AppSettings(), Brightness.light),
        builder: (context, child) => AppText(
          lang: UiLanguage.en,
          ashkenazi: true,
          child: DpadNavigation(child: child!),
        ),
        home: Scaffold(
          appBar: AppBar(
            toolbarHeight: 40,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(PageSearchBar.height),
              child: const PageSearchBar(page: 'settings', hint: 'Search settings'),
            ),
          ),
          body: ListView(children: const [
            ListTile(title: Text('Calendar settings')),
            ListTile(title: Text('Text settings')),
            ListTile(title: Text('Notifications')),
          ]),
          bottomNavigationBar: DpadNavigationBar(
            items: [NavItem.of('home')!, NavItem.of('siddur')!, NavItem.of('settings')!],
            selected: 2,
            labels: true,
            onTap: _noop,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(SearchBar)).height, lessThanOrEqualTo(32));
    expect(tester.getSize(find.byKey(const Key('dpad-bottom-navigation-size'))).height, 48);
  });
}

void _noop(int _) {}
