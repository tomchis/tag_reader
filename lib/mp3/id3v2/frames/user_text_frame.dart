import 'package:tag_reader/mp3/id3v2/enums/frames.dart';
import 'package:tag_reader/mp3/id3v2/enums/text_encoding.dart';
import 'package:tag_reader/mp3/id3v2/frames/frame.dart';
import 'package:tag_reader/mp3/id3v2/frames/unhandled.dart';
import 'package:tag_reader/util/byte_reader.dart';

/// User defined text information frame:
class UserTextFrame extends Frame {
  UserTextFrame(super.size);

  String? text;

  /// MediaMarkers chapters are represented as "OverDrive MediaMarkers".
  String? description;

  @override
  Frame parse(ByteReader reader) {
    final encodingInt = reader.readByte();

    final encoding = TextEncoding.fromInt(encodingInt);
    if (encoding == null) {
      final identifier = Frames.userDefinedText.name;
      log.info("Coudn't determine encoding for $identifier. Skipping.");
      return Unhandled(identifier, size);
    }

    description = reader.readNullTerminatedString(encoding);

    text = reader.readNullTerminatedString(encoding);

    return this;
  }
}
