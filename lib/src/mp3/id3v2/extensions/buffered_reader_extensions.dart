import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:tag_reader/src/mp3/id3v2/enums/frames.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/frame.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/unhandled.dart';
import 'package:tag_reader/src/util/buffered_reader.dart';

const _compressedFlag = 1 << 7;
const _encryptedFlag = 1 << 6;

/// Frame flags are two bytes abc00000  ijk00000
/// a = Tag alter preservation
/// b = File alter preservation
/// c = Frame is read only
/// i = Frame is compressed with zlib
/// j = Frame is encrypted
/// k = Grouping identity
typedef _Id3v2FrameHeader = ({String identifier, int size, int flags});

final _log = Logger('Id3v2Extensions');

extension Id3v2Extensions on BufferedReader {
  Future<_Id3v2FrameHeader?> _readFrameHeader(
    bool syncSafe,
    bool majorVersionLessThanThree,
  ) async {
    // Identifiers in major versions less than three will be three bytes long
    // e.g. TT2 for title, in versions after two they will be four e.g. TIT2.
    final identifierBytes = await read(majorVersionLessThanThree ? 3 : 4);

    // Check if id is null bytes
    if (identifierBytes.isEmpty || identifierBytes.elementAt(0) == 0) {
      return null;
    }

    final identifier = latin1.decode(identifierBytes);

    final size = majorVersionLessThanThree
        ? await readUint(3)
        : (syncSafe ? await readSyncSafeInt() : await readUint32());

    final flags = majorVersionLessThanThree ? 0 : await readUint16();

    return (identifier: identifier, size: size, flags: flags);
  }

  /// Returns the frame, null if end of tag.
  Future<Frame?> readNextFrame({
    required bool sizeIsSyncSafe,
    required bool majorVersionLessThanThree,
  }) async {
    final header = await _readFrameHeader(
      sizeIsSyncSafe,
      majorVersionLessThanThree,
    );
    if (header == null) return null;

    final (:identifier, :size, :flags) = header;

    final compressed = flags & _compressedFlag != 0;
    if (compressed) {
      // Skip decompressed size.
      await skip(4);
    }

    final encrypted = flags & _encryptedFlag != 0;
    if (encrypted) {
      await skip(size);
      _log.info('Encrpyted frames are not supported. Skipping ($identifier).');
      return Unhandled(identifier, size);
    }

    if (identifier == Frames.coverArt.name) {
      if (imageMode == .none) {
        await skip(size);
        _log.info('skipImages is true and already have image, skipping.');
        return Unhandled('$identifier already have image.', size);
      } else if (imageMode == .first) {
        imageMode = .none;
      }
    }

    return await Frame.parseFrom(
      identifier: identifier,
      size: size,
      reader: this,
      compressed: compressed,
    );
  }
}
