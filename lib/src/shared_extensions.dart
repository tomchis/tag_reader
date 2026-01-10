import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:tag_reader/src/models/cover_art.dart';

extension SkipExtension on RandomAccessFile {
  Future<void> skip(int bytes) async => setPosition(await position() + bytes);
}

extension StringExtension on String {
  String trimIncludingNullBytes() => trim().replaceAll('\x00', '');
}

extension IntReadingExtensions on Uint8List {
  /// Size is in bytes
  int getInt(int size, {int offset = 0}) =>
      getUint(size, offset: offset).toSigned(size);
  int getInt8([int offset = 0]) => buffer.asByteData().getInt8(offset);
  int getInt16([int offset = 0, Endian endian = Endian.big]) =>
      buffer.asByteData().getInt16(offset, endian);
  int getInt32([int offset = 0, Endian endian = Endian.big]) =>
      buffer.asByteData().getInt32(offset, endian);
  int getInt64([int offset = 0, Endian endian = Endian.big]) =>
      buffer.asByteData().getInt64(offset, endian);

  /// Size is in bytes
  int getUint(int size, {int offset = 0}) {
    assert(size > 0);
    int shiftAmount = (size * 8) - 8;
    int index = offset;
    int value = 0;
    while (shiftAmount >= 0) {
      value = value | this[index] << shiftAmount;
      shiftAmount -= 8;
      index++;
    }
    return value;
  }

  int getUint8([int offset = 0]) => buffer.asByteData().getUint8(offset);
  int getUint16([int offset = 0, Endian endian = Endian.big]) =>
      buffer.asByteData().getUint16(offset, endian);
  int getUint32([int offset = 0, Endian endian = Endian.big]) =>
      buffer.asByteData().getUint32(offset, endian);
  int getUint64([int offset = 0, Endian endian = Endian.big]) =>
      buffer.asByteData().getInt64(offset, endian);

  int getSyncsafeInt([int offset = 0]) =>
      elementAt(offset + 0) << 21 |
      elementAt(offset + 1) << 14 |
      elementAt(offset + 2) << 7 |
      elementAt(offset + 3);

  double getFloat32([int offset = 0, Endian endian = Endian.big]) =>
      buffer.asByteData().getFloat32(offset, endian);
  double getFloat64([int offset = 0, Endian endian = Endian.big]) =>
      buffer.asByteData().getFloat64(offset, endian);
}

extension StringMimeExtension on String {
  CoverFormat toCoverFormatFromMime() {
    if (contains(RegExp('jp[eg]', caseSensitive: false))) {
      return CoverFormat.jpeg;
    } else if (contains(RegExp('png', caseSensitive: false))) {
      return CoverFormat.png;
    } else if (contains(RegExp('bmp', caseSensitive: false))) {
      return CoverFormat.bmp;
    } else if (contains(RegExp('webp', caseSensitive: false))) {
      return CoverFormat.webp;
    } else if (contains(RegExp('gif', caseSensitive: false))) {
      return CoverFormat.gif;
    } else if (this == '–>') {
      return CoverFormat.url;
    }
    return CoverFormat.unknown;
  }
}

final _timeRegex = RegExp(r'(\d{1,2}:){0,2}\d{1,2}\.{1,3}');

extension TimeStringExtension on String {
  /// Fomatted as hh:mm:ss.mmm, mm:ss.mmm or ss.mmm
  int? toMillis() {
    if (!_timeRegex.hasMatch(this)) return null;

    final components = split(RegExp('[:|.]')).reversed;
    try {
      final hours = components.length == 4
          ? int.parse(components.elementAt(3))
          : 0;
      final mins = components.length >= 3
          ? int.parse(components.elementAt(2))
          : 0;
      final seconds = int.parse(components.elementAt(1));
      final millis = int.parse(components.elementAt(0));
      return Duration(
        hours: hours,
        minutes: mins,
        seconds: seconds,
        milliseconds: millis,
      ).inMilliseconds;
    } catch (e) {
      Logger(
        'TimeStringExtension',
      ).warning('Failed to parse time from $this. $e');
      return null;
    }
  }
}
