import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tag_reader/src/mp4/atoms/moov/moov.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/edts/edts.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/edts/elst.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/hdlr.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/mdhd.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/mdia.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/minf/minf.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/minf/stbl/stbl.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/minf/stbl/stco.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/minf/stbl/stsz.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/mdia/minf/stbl/stts.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/tkhd.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/trak.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/tref/chap.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/tref/tref.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/chpl.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/covr.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/data.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/generic_integer.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/generic_string.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/ilst.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/ilst/part_and_total.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/meta/meta.dart';
import 'package:tag_reader/src/mp4/atoms/moov/udta/udta.dart';
import 'package:tag_reader/src/mp4/atoms/unhandled.dart';
import 'package:tag_reader/src/mp4/enums/atoms.dart';
import 'package:tag_reader/src/mp4/extensions/buffered_reader_extensions.dart';
import 'package:tag_reader/src/util/buffered_reader.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

abstract class Atom {
  Atom(this.size);
  final int size;

  /// Sets the reader to the start of the next atom.
  Future<Atom> skip(BufferedReader reader) async {
    await reader.skip(size);
    return this;
  }

  static FutureOr<Atom> parseFrom({
    required String identifier,
    required int size,
    required BufferedReader reader,
  }) async {
    final identifierEnum = Atoms.values.firstWhereOrNull(
      (element) => element.identifier == identifier,
    );

    return switch (identifierEnum) {
      // Leaf atoms //
      .chap => await Chap(size).parse(ByteReader(await reader.read(size))),
      .chpl => await Chpl(size).parse(ByteReader(await reader.read(size))),
      .data => await Data(size).parse(ByteReader(await reader.read(size))),
      .elst => await Elst(size).parse(ByteReader(await reader.read(size))),
      .hdlr => await Hdlr(size).parse(ByteReader(await reader.read(size))),
      .mdhd => await Mdhd(size).parse(ByteReader(await reader.read(size))),
      .stts => await Stts(size).parse(ByteReader(await reader.read(size))),
      .tkhd => await Tkhd(size).parse(ByteReader(await reader.read(size))),
      // Atoms with children //
      .covr => await Covr(size).parse(reader),
      .edts => await Edts(size).parse(reader),
      .ilst => await Ilst(size).parse(reader),
      .mdia => await Mdia(size).parse(reader),
      .meta => await Meta(size).parse(reader),
      .minf => await Minf(size).parse(reader),
      .moov => await Moov(size).parse(reader),
      .stbl => await Stbl(size).parse(reader),
      .trak => await Trak(size).parse(reader),
      .tref => await Tref(size).parse(reader),
      .udta => await Udta(size).parse(reader),
      .disk || .trkn => await PartAndTotal(size, identifier).parse(reader),
      .geId => await GenericInteger(size, identifier).parse(reader),
      .aArt ||
      .alb ||
      .art ||
      .com ||
      .day ||
      .des ||
      .desc ||
      .genr ||
      .gen ||
      .gnre ||
      .nam ||
      .nrt => await GenericString(size, identifier).parse(reader),
      // Manually parsed by _buildChapters() in mp4_file. //
      .co64 || .stco => await Stco(
        size,
        identifier,
        await reader.position(),
      ).skip(reader),
      .stsz => await Stsz(size, await reader.position()).skip(reader),
      null => await Unhandled(size, identifier).skip(reader),
    };
  }
}

abstract class AtomLeaf extends Atom {
  AtomLeaf(super.size);
  FutureOr<Atom> parse(ByteReader reader);
}

class AtomWithChildren extends Atom {
  AtomWithChildren(super.size);
  final List<Atom> children = [];

  void checkRequiredChildren(List<Type> atomTypes) {
    final List<Type> missing = [];
    for (final t in atomTypes) {
      if (children.firstWhereOrNull((element) => element.runtimeType == t) ==
          null) {
        missing.add(t);
      }
    }

    if (missing.isNotEmpty) {
      final message =
          '$runtimeType has required children missing (${missing.join(', ')}).';
      throw RequiredChildMissingError(message);
    }
  }

  @mustCallSuper
  FutureOr<Atom> parse(BufferedReader reader) async {
    final endPos = await reader.position() + size;

    while (await reader.position() < endPos) {
      try {
        final atom = await reader.readNextAtom();
        if (atom == null) return this;

        children.add(atom);
      } on IOException catch (e) {
        Logger(runtimeType.toString()).severe('$e');
        rethrow;
      } catch (e) {
        Logger(runtimeType.toString()).severe('$e');
        continue;
      }
    }

    return this;
  }
}

class RequiredChildMissingError extends Error {
  RequiredChildMissingError(this.message);
  final String message;

  @override
  String toString() => message;
}
