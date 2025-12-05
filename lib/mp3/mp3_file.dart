import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:tag_reader/enums/image_mode.dart';
import 'package:tag_reader/models/tag.dart';
import 'package:tag_reader/mp3/duration_extension.dart';
import 'package:tag_reader/mp3/id3v1/genres.dart';
import 'package:tag_reader/mp3/id3v2/enums/frames.dart';
import 'package:tag_reader/mp3/id3v2/enums/text_encoding.dart';
import 'package:tag_reader/mp3/id3v2/extensions/buffered_reader_extensions.dart';
import 'package:tag_reader/mp3/id3v2/extensions/list_extensions.dart';
import 'package:tag_reader/mp3/id3v2/frames/frame.dart';
import 'package:tag_reader/util/buffered_reader.dart';

// References:
// https://mutagen-specs.readthedocs.io/en/latest/id3/index.html
// https://www.codeproject.com/Articles/8295/MPEG-Audio-Frame-Header

const _id3v2HeaderSize = 10;
const _id3v1TagSize = 128;

class Mp3File {
  Mp3File(this.path, {required this.imageMode, required this.bufferSize});
  final String path;
  final ImageMode imageMode;
  final int bufferSize;

  final _log = Logger('Mp3File');
  static const extensions = ['.mp3', '.mpga'];

  late final BufferedReader _reader;
  final List<Frame> _frames = [];

  static const _id3ExtendedHeaderBit = 1 << 5;

  // TODO: 2.4 - support null seperated strings and tags at end of the file.
  // https://mutagen-specs.readthedocs.io/en/latest/id3/id3v2.4.0-structure.html#tag-location
  // https://mutagen-specs.readthedocs.io/en/latest/id3/id3v2.4.0-frames.html#seek-frame
  Future<Tag?> parseTags() async {
    Tag? tag;

    try {
      _reader = await BufferedReader.open(
        path,
        imageMode: imageMode,
        bufferSize: bufferSize,
      );
      tag = await _parseV2Tag();
    } on FileSystemException catch (e) {
      _log.severe('Failed to open "$path". $e');
      return null;
    } catch (e) {
      _log.warning('Error parsing v2 tag: $e');
    }

    // If parsing v2 tag fails, try to read v1 tag.
    try {
      tag ??= await _parseV1Tag();
    } on FileSystemException catch (e) {
      _log.severe('Failed to open "$path". $e');
      return null;
    } catch (e) {
      _log.warning('Error parsing v1 tag: $e');
    }

    if (tag == null) {
      final duration = await _reader.determineMp3Duration();
      if (duration != null) tag = Tag(duration: duration);
    }

    await _reader.dispose();

    return tag;
  }

  Future<Tag?> _parseV2Tag() async {
    final int majorVersion;
    try {
      final identifier = String.fromCharCodes(await _reader.read(3));
      if (identifier != 'ID3') {
        _log.info('No id3v2 tag for: $path');
        return null;
      }

      // All minor revisions are backwards compatible, major versions aren't.
      majorVersion = (await _reader.read(2))[0];
      if (majorVersion > 4) {
        _log.info('id3v2 version incompatible ($majorVersion) for: $path');
        return null;
      }
    } catch (e) {
      _log.info('Failed to decode id3v2 identifier for: $path. $e');
      return null;
    }

    final flags = await _reader.readByte();
    final size = await _reader.readSyncSafeInt();

    final hasExtendedHeader = (flags & _id3ExtendedHeaderBit) != 0;
    if (hasExtendedHeader) {
      final extendedSize = await _reader.readSyncSafeInt();
      await _reader.skip(extendedSize - 4);
    }

    var bytesRead = 0;
    final sizeIsSyncSafe = majorVersion == 4;
    while (size - bytesRead > _id3v2HeaderSize) {
      final Frame? frame;
      try {
        frame = await _reader.readNextFrame(
          sizeIsSyncSafe: sizeIsSyncSafe,
          majorVersionLessThanThree: majorVersion < 3,
        );
      } on IOException catch (e) {
        _log.severe('$e');
        return null;
      } catch (e) {
        _log.info('$e');
        continue;
      }

      if (frame == null) break;

      bytesRead += _id3v2HeaderSize + frame.size;

      _frames.add(frame);
    }

    // _printUnhandled(_frames);

    Tag? tag;
    try {
      tag = await _buildV2Tag(reader: _reader, tagSize: size + 10);
    } catch (e) {
      _log.info('Invalid tag for path: $path. $e');
    }

    return tag;
  }

  Future<Tag?> _buildV2Tag({
    required BufferedReader reader,
    required int tagSize,
  }) async {
    final duration = await reader.determineMp3Duration(tagSize: tagSize);
    if (duration == null) {
      _log.info('Could not determine duration from: $path');
    }

    final tag = Tag(
      title: _frames.textFrameValueWithIdentifier(Frames.title),
      artist: _frames.textFrameValueWithIdentifier(Frames.artist),
      album: _frames.textFrameValueWithIdentifier(Frames.album),
      albumArtist: _frames.textFrameValueWithIdentifier(Frames.albumArtist),
      composer: _frames.textFrameValueWithIdentifier(Frames.composer),
      genre: _frames.textFrameValueWithIdentifier(Frames.genres),
      description: await _frames.descriptionFromFrames(),
      trackNumber: _frames.textFrameValueWithIdentifier(Frames.trackNumber),
      date: _frames.dateFromFrames(),
      duration: duration,
      coverArt: _frames.coverArtFromFrames(imageMode),
      chapters: _frames.chaptersFromChapterFrames(),
    );
    return tag;
  }

  Future<Tag?> _parseV1Tag() async {
    await _reader.setPosition(await _reader.length() - _id3v1TagSize);
    final identifier = latin1.decode(await _reader.read(3));
    if (identifier != 'TAG') return null;

    final encoding = TextEncoding.latin;

    final title = await _reader.readNullTerminatedStringIn(
      30,
      encoding: encoding,
    );
    final artist = await _reader.readNullTerminatedStringIn(
      30,
      encoding: encoding,
    );
    final album = await _reader.readNullTerminatedStringIn(
      30,
      encoding: encoding,
    );
    final year = await _reader.readNullTerminatedStringIn(
      4,
      encoding: encoding,
    );
    final comment = await _reader.readNullTerminatedStringIn(
      28,
      encoding: encoding,
    );

    String? trackNum;
    if ((await _reader.bytesInFileRemaining()) >= 2) {
      trackNum = '${await _reader.readInt16()}';
    }

    final genreInt = await _reader.readByte();
    final genre = genreMap[genreInt];

    return Tag(
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      description: comment,
      trackNumber: trackNum,
      date: year,
      duration: await _reader.determineMp3Duration(),
    );
  }

  // void _printUnhandled(List<Frame> frames) {
  //   print('Unhandled:');
  //   for (final frame in frames) {
  //     if (frame is Unhandled) {
  //       print(frame.identifier);
  //     }
  //   }
  // }
}
