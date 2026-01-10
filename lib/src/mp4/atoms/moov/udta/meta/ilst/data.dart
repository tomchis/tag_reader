import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/mp4/atoms/unhandled.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

/// Data atom:
/// Represent the data of a Covr, GenericInteger or GenericString atom.
class Data extends AtomLeaf {
  Data(super.size);

  late final DataAtomType? type;
  late final Uint8List data;

  @override
  FutureOr<Atom> parse(ByteReader reader) async {
    final typeInt = reader.readUint32();
    type = DataAtomType.values.firstWhereOrNull(
      (element) => element.type == typeInt,
    );
    if (type == null) return Unhandled(size, 'Data with type $typeInt');

    // Skip locale.
    reader.skip(4);

    data = reader.read(size - 8);

    return this;
  }
}

enum DataAtomType {
  reserved(0),

  /// Without any count or NULL terminator
  utf8(1),

  /// Also known as UTF-16BE
  utf16(2),

  /// In a JFIF wrapper
  jpeg(13),

  /// In a PNG wrapper
  png(14),

  /// in milliseconds, 32-bit integer
  duration(16),

  /// in UTC, counting seconds since midnight, January 1, 1904; 32 or 64-bits
  dateTime(17),

  /// a list of enumerated values, see #Genre
  genres(18),

  /// A big-endian signed integer in 1,2,3 or 4 bytes.
  /// This data type is not supported in Timed Metadata Media. Use one of the fixed-size signed integer data types (that is, type codes 65, 66, or 67) instead.
  signedIntBE(21),

  /// A big-endian unsigned integer in 1,2,3 or 4 bytes; size of value determines integer size
  /// Note: This data type is not supported in Timed Metadata Media. Use one of the fixed-size unsigned integer data types (that is, type codes 75, 76, or 77) instead.
  unsignedIntBE(22),

  /// A big-endian 32-bit floating point value (IEEE754)
  float32BE(23),

  /// Windows bitmap format graphics
  bmp(27),

  /// QuickTime Metadata atom. A block of data having the structure of the Metadata atom defined in this specification
  quickTimeMetadata(28),

  /// 8-bit Signed Integer
  signedInt8(65),

  /// A big-endian 16-bit signed integer
  signedInt16BE(66),

  /// A big-endian 32-bit signed integer
  signedInt32BE(67),

  /// A big-endian 64-bit signed integer
  signedInt64BE(74),

  /// An 8-bit unsigned integer
  unsignedInt8(75),

  /// A big-endian 16-bit unsigned integer
  unsignedInt16BE(76),

  /// A big-endian 32-bit unsigned integer
  unsignedInt32BE(77),

  /// A big-endian 64-bit unsigned integer
  unsignedInt64BE(78),

  undefined(255);

  const DataAtomType(this.type);

  final int type;
}
