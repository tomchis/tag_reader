import 'dart:convert';

import 'package:tag_reader/src/models/chapter.dart';
import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

/// Nero chapter atom:
/// Contains complete chapter information unlike iTunes chapters which
/// need collating.
class Chpl extends AtomLeaf {
  Chpl(super.size);

  final List<Chapter> chapters = [];

  @override
  Future<Chpl> parse(ByteReader reader) async {
    // Skip version(1)/flags(3)/reserved(1)/chaptersCount(4).
    reader.skip(9);

    while (reader.bytesRemaining > 9) {
      // Time base is 1/10,000,000
      final timeStamp = reader.readUint64() ~/ 10000;

      final titleLength = reader.readByte();
      final titleBytes = reader.read(titleLength);
      final title = utf8.decode(titleBytes.toList());
      chapters.add(Chapter(title: title, start: timeStamp));
    }
    return this;
  }
}
