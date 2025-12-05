import 'package:tag_reader/mp3/id3v2/frames/apic.dart';
import 'package:tag_reader/mp4/atoms/moov/udta/meta/ilst/covr.dart';

class CoverArt {
  CoverArt({required this.format, required this.bytes});

  static CoverArt fromApicFrame(Apic apic) =>
      CoverArt(format: apic.format, bytes: apic.imageBytes);

  static CoverArt fromCovrAtom(Covr covr) =>
      CoverArt(format: covr.imageFormat, bytes: covr.bytes);

  final CoverFormat format;
  final List<int> bytes;
}

enum CoverFormat {
  bmp,
  gif,
  jpeg,
  png,

  /// ID3 supports image urls. Currently not implemented.
  url,
  webp,
  unknown,
}
