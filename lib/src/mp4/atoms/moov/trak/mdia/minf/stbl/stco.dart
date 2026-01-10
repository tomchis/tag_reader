import 'dart:async';

import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/mp4/enums/atoms.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

/// Chunk offset atom:
/// Identifies the location of each chunk of data in the media’s data stream.
class Stco extends AtomLeaf {
  Stco(super.size, this.identifier, this.positionInFile);

  /// Will be either stco or co64 for a 64bit variant
  final String identifier;
  final int positionInFile;

  late final List<int> chunkOffsetTable = [];

  /// Should be called only as required.
  @override
  FutureOr<Stco> parse(ByteReader reader) async {
    // Skip version(1), flags (3).
    reader.skip(4);

    // Skip entryCount(4).
    reader.skip(4);

    final entrySize = identifier == Atoms.co64.identifier ? 8 : 4;

    while (reader.bytesRemaining >= entrySize) {
      if (entrySize == 8) {
        chunkOffsetTable.add(reader.readUint64());
      } else {
        chunkOffsetTable.add(reader.readUint32());
      }
    }

    return this;
  }
}
