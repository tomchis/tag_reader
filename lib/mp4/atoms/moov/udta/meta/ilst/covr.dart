import 'dart:async';

import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:tag_reader/models/cover_art.dart';
import 'package:tag_reader/mp4/atoms/atom.dart';
import 'package:tag_reader/mp4/atoms/moov/udta/meta/ilst/data.dart';
import 'package:tag_reader/mp4/atoms/unhandled.dart';
import 'package:tag_reader/mp4/extensions/atom_list_extensions.dart';
import 'package:tag_reader/util/buffered_reader.dart';

/// Cover atom:
/// Represent an image.
class Covr extends AtomWithChildren {
  Covr(super.size);

  late final CoverFormat imageFormat;
  late final Uint8List bytes;
  final _jpegMagic = [0xFF, 0xD8];
  final _pngMagic = [0x89, 0x50, 0x4e, 0x47];
  final _webpMagic = [
    0x52,
    0x49,
    0x46,
    0x46,
    0x00,
    0x00,
    0x00,
    0x00,
    0x57,
    0x45,
    0x42,
    0x50,
  ];
  final _gifMagic = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61];
  final _gifMagic2 = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61];

  @override
  FutureOr<Atom> parse(BufferedReader reader) async {
    await super.parse(reader);

    final dataAtom = children.firstWhereType<Data>();
    if (dataAtom == null) {
      Logger('Covr').warning('No data atom found for covr atom');
      return Unhandled(size, 'covr with no data atom');
    }
    switch (dataAtom.type) {
      case .jpeg:
        imageFormat = CoverFormat.jpeg;
      case .png:
        imageFormat = CoverFormat.png;
      case .bmp:
        imageFormat = CoverFormat.bmp;
      case .reserved:
      case .undefined:
        final format = coverFormatFromMagicIn(data: dataAtom.data);
        if (format == null) continue unhandled;

        imageFormat = format;
      unhandled:
      case _:
        return Unhandled(size, 'covr with data type ${dataAtom.type}');
    }

    bytes = dataAtom.data;

    return this;
  }

  CoverFormat? coverFormatFromMagicIn({required Uint8List data}) {
    if (data.sublist(0, _jpegMagic.length) == _jpegMagic) {
      return CoverFormat.jpeg;
    } else if (data.sublist(0, _pngMagic.length) == _pngMagic) {
      return CoverFormat.png;
    }
    // Skip the middle 4 bytes witch are the size of the file
    else if (data.sublist(0, 4) == _webpMagic.sublist(0, 4) &&
        data.sublist(8, 11) == _webpMagic.sublist(8, 11)) {
      return CoverFormat.webp;
    } else if (data.sublist(0, _gifMagic.length) == _gifMagic ||
        data.sublist(0, _gifMagic2.length) == _gifMagic2) {
      return CoverFormat.gif;
    }
    return null;
  }
}
