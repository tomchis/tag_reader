import 'dart:async';

import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

typedef EditListEntry = ({double duration, double mediaTime, double mediaRate});

/// Edit list atom:
/// Maps from a time in a movie to a time in a media,
/// and ultimately to media data.
class Elst extends AtomLeaf {
  Elst(super.size);

  final List<double> editListTable = [];

  @override
  FutureOr<Elst> parse(ByteReader reader) async {
    final version = reader.readByte();

    // Skip flags(3), entryCount(4).
    reader.skip(7);

    final entrySize = version == 1 ? 20 : 12;
    while (reader.bytesRemaining >= entrySize) {
      double mediaTime;
      if (version == 1) {
        // Skip duration. (u64)
        reader.skip(8);
        mediaTime = reader.readFloat64();
      } else {
        // Skip duration. (u32)
        reader.skip(4);
        mediaTime = reader.readFloat32();
      }

      // Skip mediaRate(2). (f32)

      // Skip reserved(2).

      editListTable.add(mediaTime);
    }

    return this;
  }
}
