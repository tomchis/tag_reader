import 'dart:async';

import 'package:logging/logging.dart';
import 'package:tag_reader/src/mp4/atoms/atom.dart';

import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/data.dart';
import 'package:tag_reader/src/mp4/extensions/atom_list_extensions.dart';
import 'package:tag_reader/src/shared_extensions.dart';
import 'package:tag_reader/src/util/buffered_reader.dart';

/// Used to represent the disk and trkn atoms.
/// Stores the track/disk number and optional out of total.
class PartAndTotal extends AtomWithChildren {
  PartAndTotal(super.size, this.identifier);

  final String identifier;

  late int? part;
  late int? total;

  @override
  FutureOr<PartAndTotal> parse(BufferedReader reader) async {
    await super.parse(reader);

    final dataAtom = children.firstWhereType<Data>();
    if (dataAtom == null) {
      Logger('PartAndTotal').warning('No data atom found for: $identifier');
      return this;
    }

    // trkn format = 0 0 p p t t 0 0 (8 bytes)
    // disk format = 0 0 p p t t (6 bytes)
    if (dataAtom.size >= 6) {
      part = dataAtom.data.getUint16(2);
      total = dataAtom.data.getUint16(4);
    }
    // If size is >= 4 likely only contains part
    // 0 0 p p
    else if (dataAtom.size >= 4) {
      part = dataAtom.data.getUint16(2);
      total = null;
    } else {
      part = null;
      total = null;
    }

    return this;
  }

  /// If total is available part/total other part.
  String? stringValue() {
    if (part == null) return null;

    return total != null && total! > part! ? '$part/$total' : '$part';
  }
}
