import 'dart:async';

import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

/// Movie header atom:
/// Specifies the characteristics of an entire movie.
class Mvhd extends AtomLeaf {
  Mvhd(super.size);

  late final int timeScale;
  late final int duration;

  @override
  FutureOr<Mvhd> parse(ByteReader reader) async {
    final version = reader.readByte();

    // Skip flags(3), creationTime(8|4), modificationTime(8|4).
    reader.skip(version == 1 ? 19 : 11);

    timeScale = reader.readUint32();

    duration = version == 1 ? reader.readUint64() : reader.readUint32();

    return this;
  }
}
