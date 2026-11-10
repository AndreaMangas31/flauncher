/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/widgets/tv_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("D-pad focus does not open the keyboard until select", (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TvTextFormField(
              autofocus: true,
              controller: controller,
            ),
            ElevatedButton(onPressed: () {}, child: const Text("Save")),
          ],
        ),
      ),
    ));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
    expect(Focus.of(tester.element(find.text("Save"))).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);

    tester.testTextInput.enterText("Apps");
    await tester.pump();
    expect(controller.text, "Apps");

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
    expect(Focus.of(tester.element(find.text("Save"))).hasFocus, isTrue);
  });
}
