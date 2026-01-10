import 'dart:async';

import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

/// Chapter or scene list atom:
/// Stores id references, usually text tracks.
class Chap extends AtomLeaf {
  Chap(super.size);
  late final List<int> ids = [];

  @override
  FutureOr<Chap> parse(ByteReader reader) async {
    while (reader.bytesRemaining >= 4) {
      final id = reader.readUint32();
      ids.add(id);
    }

    return this;
  }
}
