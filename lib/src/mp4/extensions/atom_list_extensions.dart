import 'package:collection/collection.dart';
import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/generic_integer.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/generic_string.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/part_and_total.dart';

extension AtomListExtensions on List<Atom> {
  T? firstWhereType<T extends Atom>() =>
      firstWhereOrNull((element) => element is T) as T?;

  GenericString? firstGenericStringWith({required String identifier}) =>
      firstWhereOrNull(
            (element) =>
                element is GenericString && element.identifier == identifier,
          )
          as GenericString?;

  GenericString? firstGenericStringContaining({
    required List<String> identifiers,
  }) =>
      firstWhereOrNull(
            (element) =>
                element is GenericString &&
                identifiers.contains(element.identifier),
          )
          as GenericString?;

  GenericString? preferedGenericStringContaining({
    required List<String> identifiers,
  }) {
    assert(identifiers.isNotEmpty);
    final alts = List<GenericString?>.filled(identifiers.length - 1, null);
    for (final c in this) {
      if (c is GenericString) {
        final index = identifiers.indexOf(c.identifier);
        if (index == 0) {
          return c;
        } else if (index != -1) {
          alts[index - 1] = c;
        }
      }
    }
    return alts.firstWhereOrNull((a) => a != null);
  }

  GenericInteger? firstGenericIntegerWith({required String identifier}) =>
      firstWhereOrNull(
            (element) =>
                element is GenericInteger && element.identifier == identifier,
          )
          as GenericInteger?;

  PartAndTotal? firstPartAndTotalWith({required String identifier}) =>
      firstWhereOrNull(
            (element) =>
                element is PartAndTotal && element.identifier == identifier,
          )
          as PartAndTotal?;
}

extension IntegerToBool on GenericInteger? {
  bool? toBool() {
    if (this == null) return null;

    return this!.value == 0 ? false : true;
  }
}
