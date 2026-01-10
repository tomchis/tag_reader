import 'dart:async';

import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/chpl.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/ilst.dart';
import 'package:tag_reader/src/mp4/extensions/atom_list_extensions.dart';
import 'package:tag_reader/src/util/buffered_reader.dart';

/// Metadata atom:
/// Child atoms contain the majority of metadata we need.
class Meta extends AtomWithChildren {
  Meta(super.size);

  @override
  FutureOr<Meta> parse(BufferedReader reader) async {
    // Skip version(1), flags(3)
    reader.skip(4);
    return await super.parse(reader) as Meta;
  }

  Chpl? get chpl => children.firstWhereType<Chpl>();

  Ilst? get ilst => children.firstWhereType<Ilst>();
}
