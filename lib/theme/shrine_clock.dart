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

/// Weekday abbreviations matching "Sáb, 25 de enero". Monday is index 0,
/// matching [DateTime.weekday] minus one.
const List<String> shrineWeekdays = [
  'Lun',
  'Mar',
  'Mié',
  'Jue',
  'Vie',
  'Sáb',
  'Dom'
];

const List<String> shrineMonths = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Home-bar date. Always Spanish, independent of the device locale, so a
/// TV set to English still reads the way the shrine layout was drawn.
String formatShrineDate(DateTime date) {
  final String weekday = shrineWeekdays[date.weekday - 1];
  final String month = shrineMonths[date.month - 1];
  return '$weekday, ${date.day} de $month';
}
