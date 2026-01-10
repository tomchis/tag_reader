import 'dart:async';

import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

/// Track header atom:
/// Specifies the characteristics of a single track.
class Tkhd extends AtomLeaf {
  Tkhd(super.size);

  late final int trackId;

  @override
  FutureOr<Tkhd> parse(ByteReader reader) async {
    final version = reader.readByte();

    // Skip flags(3), creationTime(8|4), modificationTime(8|4)
    reader.skip(version == 1 ? 19 : 11);

    trackId = reader.readUint32();

    return this;
  }
}
