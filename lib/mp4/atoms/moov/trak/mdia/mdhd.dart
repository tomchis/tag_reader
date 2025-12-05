import 'dart:async';

import 'package:tag_reader/mp4/atoms/atom.dart';
import 'package:tag_reader/util/byte_reader.dart';

/// Media header atom:
/// Contains the standard media information.
class Mdhd extends AtomLeaf {
  Mdhd(super.size);

  late final int timeScale;
  late final int duration;

  @override
  FutureOr<Mdhd> parse(ByteReader reader) async {
    final version = reader.readByte();

    // Skip flags(3), creationTime(8|4), modificationTime(8|4).
    reader.skip(version == 1 ? 19 : 11);

    timeScale = reader.readUint32();

    duration = version == 1 ? reader.readUint64() : reader.readUint32();

    // Skip Language(2), quality(2).

    return this;
  }
}
