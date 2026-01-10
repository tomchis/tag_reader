import 'dart:async';

import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/hdlr.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/mdhd.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/minf/minf.dart';
import 'package:tag_reader/src/mp4/extensions/atom_list_extensions.dart';
import 'package:tag_reader/src/util/buffered_reader.dart';

/// Media atom:
/// Describes and defines a track’s media type and sample data.
class Mdia extends AtomWithChildren {
  Mdia(super.size);

  @override
  FutureOr<Mdia> parse(BufferedReader reader) async {
    await super.parse(reader);

    try {
      checkRequiredChildren([Mdhd]);
    } on RequiredChildMissingError {
      rethrow;
    }

    return this;
  }

  Hdlr? get hdlr => children.firstWhereType<Hdlr>();
  Mdhd get mdhd => children.firstWhereType<Mdhd>()!;
  Minf? get minf => children.firstWhereType<Minf>();
}
