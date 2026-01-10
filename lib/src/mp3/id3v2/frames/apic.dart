import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:tag_reader/src/models/cover_art.dart';
import 'package:tag_reader/src/mp3/id3v2/enums/picture_type.dart';
import 'package:tag_reader/src/mp3/id3v2/enums/text_encoding.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/frame.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/unhandled.dart';
import 'package:tag_reader/src/shared_extensions.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

/// Picture frame:
class Apic extends Frame {
  Apic(super.size, {required this.majorVersionLessThanThree});

  final bool majorVersionLessThanThree;
  late final List<int> imageBytes;
  late final CoverFormat format;
  late final PictureType type;

  @override
  Frame parse(ByteReader reader) {
    final encodingInt = reader.readByte();

    final encoding = TextEncoding.fromInt(encodingInt);
    if (encoding == null) {
      log.info("Coudn't determine encoding for Apic. Skipping.");
      return Unhandled('Apic', size);
    }

    // In Pic frames from id3 major versions less than three, mime will be 3 bytes
    // e.g. JPG or PNG.
    final mimeType = majorVersionLessThanThree
        ? latin1.decode(reader.read(3))
        : reader.readNullTerminatedString(TextEncoding.latin);
    format = mimeType!.toCoverFormatFromMime();

    if (format == CoverFormat.url) {
      return Unhandled('apic with url', size);
    }

    final pictureInt = reader.readByte();
    type =
        PictureType.values.firstWhereOrNull(
          (element) => element.identifier == pictureInt,
        ) ??
        PictureType.unknown;

    // Skip description.
    reader.skipNullTerminatedString(encoding);

    imageBytes = reader.readToEnd();

    return this;
  }
}
