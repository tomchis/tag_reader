import 'dart:convert';

import 'package:tag_reader/src/mp3/id3v2/enums/text_encoding.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/frame.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/text_frame.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

/// Chapter frame:
/// Contains full chapter information.
class Chap extends Frame {
  Chap(super.size);

  late final String id;
  late final String? title;
  late final String? description;
  late final int startMillis;
  late final int endMillis;

  @override
  Chap parse(ByteReader reader) {
    id = reader.readNullTerminatedString(TextEncoding.latin)!;
    startMillis = reader.readUint32();
    endMillis = reader.readUint32();

    // Skip startOffset(4), endOffset(4).
    reader.skip(8);

    title = reader.bytesRemaining > 10 ? _readValueFromNextFrame(reader) : null;

    description = reader.bytesRemaining > 10
        ? _readValueFromNextFrame(reader)
        : null;

    return this;
  }

  /// Reads the next subframe.
  String? _readValueFromNextFrame(ByteReader reader) {
    final id = latin1.decode(reader.read(4));
    final size = reader.readSyncSafeInt();

    // Skip flags.
    reader.skip(2);

    final frame = TextFrame(id, size).parse(ByteReader(reader.read(size)));
    // If null, the frame will be of Unhandled.
    return frame is TextFrame ? frame.text : null;
  }
}
