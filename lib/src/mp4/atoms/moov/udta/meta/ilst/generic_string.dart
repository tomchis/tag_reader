import 'dart:async';
import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:logging/logging.dart';

import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/data.dart';
import 'package:tag_reader/src/mp4/atoms/unhandled.dart';
import 'package:tag_reader/src/mp4/extensions/atom_list_extensions.dart';
import 'package:tag_reader/src/shared_extensions.dart';
import 'package:tag_reader/src/util/buffered_reader.dart';

/// Generic class representing atoms with with a data atom
/// containing a string value.
class GenericString extends AtomWithChildren {
  GenericString(super.size, this.identifier);

  final String identifier;
  late final String? value;
  final _log = Logger('GenericString');

  @override
  FutureOr<Atom> parse(BufferedReader reader) async {
    await super.parse(reader);

    final dataAtom = children.firstWhereType<Data>();
    if (dataAtom == null) {
      _log.warning('No data atom found for: $identifier');
      value = null;
      return this;
    }
    try {
      switch (dataAtom.type) {
        case .utf8:
        case .genres:
          value = utf8.decode(dataAtom.data);
        case .utf16:
          value = utf16.decode(dataAtom.data).trimIncludingNullBytes();
        case .signedIntBE:
          final int = dataAtom.data.getInt(dataAtom.size);
          value = '$int';
        case .signedInt8:
          value = '${dataAtom.data.getInt8()}';
        case .signedInt16BE:
          value = '${dataAtom.data.getInt16()}';
        case .signedInt32BE:
          value = '${dataAtom.data.getInt32()}';
        case .signedInt64BE:
          value = '${dataAtom.data.getInt64()}';
        case _:
          return Unhandled(size, '$identifier with data type ${dataAtom.type}');
      }
    } catch (e) {
      value = null;
      _log.info('Failed to decode identifier: $identifier. $e');
    }

    return this;
  }
}
