import 'package:flauncher/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Element? findAppCardByPackageName(WidgetTester tester, String packageName) {
  for (final Element card in tester.elementList(find.byType(AppCard))) {
    if ((card.widget as AppCard).application.packageName != packageName) {
      continue;
    }
    // The card's focus node is a descendant. Focus.of needs a context under
    // that node, so return the InkWell rather than the AppCard itself.
    Element? ink;
    void visit(Element element) {
      if (ink == null && element.widget is InkWell) {
        ink = element;
      }
      element.visitChildren(visit);
    }

    visit(card);
    return ink ?? card;
  }
  return null;
}

Element? findSettingsIcon(WidgetTester tester) {
  // this function seems strange, but this is the simplest way I had to find the settings icon button
  for (var val in tester.elementList(find.byIcon(Icons.settings_outlined))) {
    if (((val as StatelessElement).widget as Icon).color == null) {
      return val;
    }
  }
  return null;
}
