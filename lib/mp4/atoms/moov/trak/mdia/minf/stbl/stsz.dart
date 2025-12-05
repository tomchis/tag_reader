import 'dart:async';

import 'package:tag_reader/mp4/atoms/atom.dart';
import 'package:tag_reader/util/byte_reader.dart';

/// Sample size atom:
/// Specifies the size of each sample in the media.
class Stsz extends AtomLeaf {
  Stsz(super.size, this.positionInFile);

  final int positionInFile;

  late final int entryCount;
  late final int sampleSize;

  /// Empty if sample sizes are all the same
  final List<int> sampleSizeTable = [];

  /// Should be called only as required.
  @override
  FutureOr<Stsz> parse(ByteReader reader) async {
    // Skip version(1), flags(3).
    reader.skip(4);

    sampleSize = reader.readUint32();

    entryCount = reader.readUint32();

    // If 0 samples have different sizes.
    if (sampleSize == 0) {
      while (reader.bytesRemaining >= 4) {
        final size = reader.readUint32();
        sampleSizeTable.add(size);
      }
    }

    return this;
  }
}
