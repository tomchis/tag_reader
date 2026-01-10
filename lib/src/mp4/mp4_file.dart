import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:tag_reader/src/enums/image_mode.dart';
import 'package:tag_reader/src/models/chapter.dart';
import 'package:tag_reader/src/models/cover_art.dart';
import 'package:tag_reader/src/models/tag.dart';
import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/mp4/atoms/moov/moov.dart';
import 'package:tag_reader/src/mp4/atoms/unhandled.dart';
import 'package:tag_reader/src/mp4/enums/atoms.dart';
import 'package:tag_reader/src/mp4/extensions/atom_list_extensions.dart';
import 'package:tag_reader/src/mp4/extensions/buffered_reader_extensions.dart';
import 'package:tag_reader/src/util/buffered_reader.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

// References:
// https://github.com/NCrusher74/SwiftTagger
// https://developer.apple.com/documentation/quicktime-file-format

class Mp4File {
  Mp4File(this.path, {required this.imageMode, required this.bufferSize});

  final String path;
  final ImageMode imageMode;
  final int bufferSize;

  final _log = Logger('Mp4File');
  static const extensions = ['.m4a', '.m4b', '.mp4', '.m4r'];

  late final BufferedReader _reader;
  final List<Atom> _rootAtoms = [];

  Future<Tag?> parseTags() async {
    try {
      _reader = await BufferedReader.open(
        path,
        imageMode: imageMode,
        bufferSize: bufferSize,
      );
      final initialAtom = await _reader.readNextAtom() as Unhandled?;
      if (initialAtom == null || initialAtom.identifier != 'ftyp') {
        _log.severe('Initial ftyp atom not found. Not an mp4?');
        await _reader.dispose();
        return null;
      }
    } on FileSystemException catch (e) {
      _log.severe('Failed to open "$path". $e');
      return null;
    } catch (e) {
      _log.severe('$e');
      await _reader.dispose();
      return null;
    }

    while (true) {
      final Atom? atom;
      try {
        atom = await _reader.readNextAtom();
      } on RequiredChildMissingError catch (e) {
        await _reader.dispose();
        _log.warning('$e');
        return null;
      } catch (e, s) {
        await _reader.dispose();
        _log.severe('$e\n$s');
        return null;
      }

      if (atom == null) break;

      _rootAtoms.add(atom);
    }

    // _printAtomTree(_rootAtoms);

    Tag? tag;
    try {
      tag = await _buildTag();
    } catch (e) {
      _log.warning('Invalid tag for path: $path');
      tag = null;
    }
    await _reader.dispose();

    return tag;
  }

  Future<Tag> _buildTag() async {
    final moov = _rootAtoms.firstWhereType<Moov>()!;
    final udta = moov.udtaWithMetadata;
    final ilst = udta?.meta?.ilst;

    final tag = Tag(
      title: ilst?.firstStringWith(identifier: Atoms.nam.identifier),
      artist: ilst?.firstStringWith(identifier: Atoms.art.identifier),
      albumArtist: ilst?.firstStringWith(identifier: Atoms.aArt.identifier),
      album: ilst?.firstStringWith(identifier: Atoms.alb.identifier),
      composer: ilst?.preferedStringContaining(
        identifiers: [Atoms.com.identifier, Atoms.nrt.identifier],
      ),
      genre: ilst?.genreFromAtoms(),
      date: ilst?.firstStringWith(identifier: Atoms.day.identifier),
      description: ilst?.descriptionFromAtoms(),
      trackNumber: ilst?.firstPartAndTotalWith(
        identifier: Atoms.trkn.identifier,
      ),
      duration: moov.duration,
      coverArt: ilst
          ?.covrAtoms(imageMode)
          ?.map((e) => CoverArt.fromCovrAtom(e))
          .toList(),
      chapters: await _buildChapters(moov),
    );

    return tag;
  }

  FutureOr<List<Chapter>?> _buildChapters(Moov moov) async {
    final neroChapters = moov.udta?.chpl?.chapters;
    if (neroChapters != null) return neroChapters;

    // Try to collate iTunes style chapters.
    final chapterTrak = moov.chapterTrak;
    if (chapterTrak == null) return null;

    final stbl = chapterTrak.mdia.minf?.stbl;
    if (stbl == null) return null;

    final timeScale = chapterTrak.mdia.mdhd.timeScale;

    final soundTrak = moov.soundTrak;
    if (soundTrak == null) return null;

    final elst = soundTrak.edts?.elst;
    final int initialStartTime = elst != null
        ? (elst.editListTable.first / timeScale * 1000).toInt()
        : 0;

    final startTimes = stbl.stts?.getStartTimes(timeScale, initialStartTime);
    if (startTimes == null || startTimes.isEmpty) return null;

    final stco = stbl.stco;
    if (stco == null) return null;
    await _reader.setPosition(stco.positionInFile);
    final offsets = (await stco.parse(
      ByteReader(await _reader.read(stco.size)),
    )).chunkOffsetTable;

    final stsz = stbl.stsz;
    if (stsz == null) return null;
    await _reader.setPosition(stsz.positionInFile);
    await stbl.stsz?.parse(ByteReader(await _reader.read(stsz.size)));

    final List<int> sizes = stsz.sampleSize == 0
        ? stsz.sampleSizeTable
        : List.generate(stsz.entryCount, (_) => stsz.sampleSize);

    final titles = await stbl.getChapterTitles(
      offsets: offsets,
      sizes: sizes,
      reader: _reader,
    );

    if (startTimes.length > titles.length) {
      final diff = startTimes.length - titles.length;
      titles.addAll(
        List.generate(diff, (index) => 'Chapter ${titles.length + index + 1}'),
      );
    }

    final List<Chapter> chapters = [];
    for (final (index, startTime) in startTimes.indexed) {
      chapters.add(Chapter(title: titles[index], start: startTime));
    }

    return chapters;
  }

  // void _printAtomTree(List<Atom> atoms, [int level = 0]) {
  //   String levelIndicator = level > 0
  //       ? '${List.generate(level, (_) => '-').join()} '
  //       : '';
  //   for (var child in atoms) {
  //     String identifier = '';
  //     String value = '';
  //     if (child is GenericString) {
  //       identifier = ' (${child.identifier})';
  //       value = ' ${child.value}';
  //     } else if (child is GenericInteger) {
  //       identifier = ' (${child.identifier})';
  //       value = ' ${child.value}';
  //     } else if (child is Hdlr) {
  //       identifier = '(${child.subtype})';
  //     } else if (child is Unhandled) {
  //       identifier = ' (${child.identifier})';
  //     }
  //
  //     final size = '${(child.size / 1024).toStringAsFixed(1)} kb';
  //     final info = '${child.runtimeType}$identifier$value ($size)';
  //     print('$levelIndicator$info');
  //     if (child is AtomWithChildren) {
  //       _printAtomTree(child.children, level + 1);
  //     }
  //   }
  // }
}
