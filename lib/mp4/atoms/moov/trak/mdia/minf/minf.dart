import 'dart:async';

import 'package:tag_reader/mp4/atoms/atom.dart';
import 'package:tag_reader/mp4/atoms/moov/trak/mdia/minf/stbl/stbl.dart';
import 'package:tag_reader/mp4/extensions/atom_list_extensions.dart';
import 'package:tag_reader/util/buffered_reader.dart';

/// Media information atom:
/// Contains atoms that define specific characteristics
/// of the media data.
class Minf extends AtomWithChildren {
  Minf(super.size);

  @override
  FutureOr<Minf> parse(BufferedReader reader) async {
    await super.parse(reader);

    try {
      checkRequiredChildren([Stbl]);
    } on RequiredChildMissingError {
      rethrow;
    }

    return this;
  }

  Stbl get stbl => children.firstWhereType<Stbl>()!;
}
