import 'package:tag_reader/mp3/id3v2/enums/frames.dart';
import 'package:tag_reader/mp3/id3v2/enums/text_encoding.dart';
import 'package:tag_reader/mp3/id3v2/frames/frame.dart';
import 'package:tag_reader/mp3/id3v2/frames/unhandled.dart';
import 'package:tag_reader/util/byte_reader.dart';

/// Can be used as an alternative to description. May have more than with the
/// same data but in a different language.
class CommentFrame extends Frame {
  CommentFrame(super.size);

  String? shortText;
  String? text;
  late String language;

  @override
  Frame parse(ByteReader reader) {
    final encodingInt = reader.readByte();
    final encoding = TextEncoding.fromInt(encodingInt);
    if (encoding == null) {
      final identifier = Frames.comment.name;
      log.info("Coudn't determine encoding for $identifier. Skipping.");
      return Unhandled(identifier, size);
    }

    language = String.fromCharCodes(reader.read(3));

    shortText = reader.readNullTerminatedString(encoding);
    if (shortText != null && shortText!.isEmpty) shortText = null;

    text = reader.readNullTerminatedString(encoding);
    if (text != null && text!.isEmpty) text = null;

    return this;
  }
}
