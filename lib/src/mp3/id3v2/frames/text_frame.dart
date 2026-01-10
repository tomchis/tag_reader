import 'package:tag_reader/src/mp3/id3v2/enums/text_encoding.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/frame.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/unhandled.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

/// Text frame:
/// Represents the majority of the metadata.
class TextFrame extends Frame {
  TextFrame(this.identifier, super.size);

  // Will be T000 - TZZZ, exluding TXXX
  final String identifier;
  String? text;

  @override
  Frame parse(ByteReader reader) {
    final encodingInt = reader.readByte();

    // TODO: id3 v2.4 supports multiple strings stored as a null
    // separatedlist, where null is reperesented by the termination
    // code for the character encoding.
    final encoding = TextEncoding.fromInt(encodingInt);
    if (encoding == null) {
      log.info("Coudn't determine encoding for $identifier. Skipping.");
      return Unhandled(identifier, size);
    }

    text = reader.readNullTerminatedString(encoding);

    return this;
  }

  int? textToInt() {
    if (text == null) return null;

    return int.tryParse(text!);
  }
}
