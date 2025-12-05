import 'dart:async';
import 'dart:convert';

import 'package:tag_reader/mp4/atoms/atom.dart';
import 'package:tag_reader/util/byte_reader.dart';

/// Handler reference atom:
/// Specifies the media handler component that is to be used to interpret
/// the media’s data.
class Hdlr extends AtomLeaf {
  Hdlr(super.size);

  late final String subtype;

  @override
  FutureOr<Hdlr> parse(ByteReader reader) async {
    // Skip version(1), flags(3).
    reader.skip(4);

    // Skip type. (latin1)
    reader.skip(4);

    subtype = latin1.decode(reader.read(4));

    // Skip reserved.
    reader.skip(12);

    // Skip name. (latin1)

    return this;
  }
}
