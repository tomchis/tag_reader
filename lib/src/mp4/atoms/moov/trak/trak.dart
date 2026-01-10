import 'dart:async';

import 'package:collection/collection.dart';
import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/edts/edts.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/mdia.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/tkhd.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/tref/chap.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/tref/tref.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/udta.dart';
import 'package:tag_reader/src/mp4/extensions/atom_list_extensions.dart';
import 'package:tag_reader/src/util/buffered_reader.dart';

/// Track atom:
/// Defines a single track of a movie.
class Trak extends AtomWithChildren {
  Trak(super.size);

  @override
  FutureOr<Trak> parse(BufferedReader reader) async {
    await super.parse(reader);

    try {
      checkRequiredChildren([Mdia, Tkhd]);
    } on RequiredChildMissingError {
      rethrow;
    }

    return this;
  }

  Udta? get udta => children.firstWhereType<Udta>();
  Edts? get edts => children.firstWhereType<Edts>();
  Mdia get mdia => children.firstWhereType<Mdia>()!;
  Tkhd get tkhd => children.firstWhereType<Tkhd>()!;

  Chap? get chap {
    final trefs = children.whereType<Tref>();
    for (final Tref(:children) in trefs) {
      return children.firstWhereOrNull((element) => element is Chap) as Chap?;
    }
    return null;
  }
}

enum TrakType {
  /// compressed and uncompressed image
  vide,

  /// compressed and uncompressed audio data
  soun,

  ///text data
  text,

  subt,

  /// timed metadata
  meta,

  /// time code data
  tmcd,

  /// closed caption text data
  clcp,

  /// subtitle text data
  sbtl,

  /// note-based audio data, such as MIDI data
  musi,

  /// MPEG-1 video streams, MPEG-1, layer 2 audio streams, and multiplexed MPEG-1 audio and video streams
  // ignore: constant_identifier_names
  MPEG,

  sprt,

  /// deprecated
  twen,

  /// deprecated
  tx3g,

  unknown,
}
