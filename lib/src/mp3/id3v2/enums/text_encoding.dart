import 'package:collection/collection.dart';

enum TextEncoding {
  latin(0),
  utf16(1),
  utf16be(2),
  utf8(3);

  const TextEncoding(this.encoding);
  final int encoding;

  static TextEncoding? fromInt(int? encoding) => encoding != null
      ? values.firstWhereOrNull((element) => element.encoding == encoding)
      : null;
}
